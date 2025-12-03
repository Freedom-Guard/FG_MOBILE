import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:Freedom_Guard/ui/widgets/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:Freedom_Guard/components/f-link.dart';
import 'package:Freedom_Guard/core/local.dart';
import 'package:Freedom_Guard/components/servers.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/main.dart';
import 'package:Freedom_Guard/ui/screens/cfg_screen.dart';
import 'package:Freedom_Guard/services/config.dart';
import 'package:Freedom_Guard/ui/widgets/encrypt.dart';
import 'package:Freedom_Guard/ui/widgets/enter_config.dart';
import 'package:Freedom_Guard/ui/widgets/qr_code.dart';

enum ViewMode { list, grid }

class ServersPage extends StatefulWidget {
  const ServersPage({super.key});
  @override
  State<ServersPage> createState() => _ServersPageState();
}

class _ServersPageState extends State<ServersPage> with RouteAware {
  bool isLoading = true;
  List<String> servers = [];
  List<String> filteredServers = [];
  late ServersM serversManage;
  late SettingsApp settings;
  final TextEditingController serverController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final Map<String, int?> serverPingTimes = {};
  bool isPingingAll = false;
  bool sortByPing = false;
  ViewMode viewMode = ViewMode.list;
  Set<String> selectedServers = {};
  bool multiSelectMode = false;

  @override
  void initState() {
    super.initState();
    settings = SettingsApp();
    serversManage = Provider.of<ServersM>(context, listen: false);
    searchController.addListener(_applyFiltersAndSort);
    Future.microtask(_loadAll);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    serverController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void didPopNext() {
    _restoreServers();
  }

  Future<void> _loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String? modeName = prefs.getString("viewMode");
      if (modeName != null) {
        viewMode = ViewMode.values.firstWhere(
          (v) => v.name == modeName,
          orElse: () => ViewMode.list,
        );
      }
      await serversManage.getSelectedServer();
      await _restoreServers(initialLoad: true);
      await _restorePingTimes();
      await _restoreSelectedServer();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _applyFiltersAndSort() {
    String query = searchController.text.toLowerCase();
    List<String> temp = query.isEmpty
        ? List.from(servers)
        : servers
            .where((s) => getNameByConfig(s).toLowerCase().contains(query))
            .toList();
    if (sortByPing) {
      temp.sort((a, b) {
        int pingA =
            serverPingTimes[a] == -1 ? 9999 : serverPingTimes[a] ?? 9999;
        int pingB =
            serverPingTimes[b] == -1 ? 9999 : serverPingTimes[b] ?? 9999;
        return pingA.compareTo(pingB);
      });
    }
    if (mounted) setState(() => filteredServers = temp);
  }

  Future<void> _savePrefs(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool)
      await prefs.setBool(key, value);
    else if (value is String)
      await prefs.setString(key, value);
    else if (value is List<String>)
      await prefs.setStringList(key, value);
    else if (value is Map<String, dynamic>)
      await prefs.setString(key, jsonEncode(value));
  }

  Future<void> _loadPrefs(String key, {Type? type}) async {
    final prefs = await SharedPreferences.getInstance();
    if (type == Map<String, dynamic>) {
      final data = prefs.getString(key);
      if (data != null) {
        final map = jsonDecode(data) as Map<String, dynamic>;
        map.forEach((k, v) =>
            serverPingTimes[k] = v == 'null' ? null : int.tryParse(v));
      }
    }
  }

  Future<void> _restoreServers({bool initialLoad = false}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList('servers') ?? [];
    if (initialLoad && list.isEmpty) {
      await _refreshSubscriptions();
      list = prefs.getStringList('servers') ?? [];
    }
    if (mounted) {
      setState(() => servers = list);
      _applyFiltersAndSort();
    }
  }

  Future<void> _refreshSubscriptions() async {
    await serversManage.loadServers();
    await _restoreServers();
  }

  Future<void> _restoreSelectedServer() async {
    final prefs = await SharedPreferences.getInstance();
    final selected = prefs.getString('selectedServer');
    if (selected != null && servers.contains(selected))
      await serversManage.selectServer(selected);
  }

  Future<void> _saveServers() async {
    await _savePrefs('servers', servers);
    _applyFiltersAndSort();
  }

  Future<void> _restorePingTimes() async =>
      await _loadPrefs('pingTimes', type: Map<String, dynamic>);
  Future<void> _savePingTimes() async {
    final map =
        serverPingTimes.map((k, v) => MapEntry(k, v?.toString() ?? 'null'));
    await _savePrefs('pingTimes', map);
  }

  void _addServer(String name) {
    if (name.isNotEmpty && !servers.contains(name)) {
      setState(() => servers.insert(0, name));
      serversManage.selectServer(name);
      _saveServers();
      serverController.clear();
    } else {
      serversManage.selectServer(name);
    }
  }

  void _confirmRemoveServer(String server) {
    showDialog(
      context: context,
      builder: (ctx) => AppDialogs.buildDialog(
        context: ctx,
        title: tr('delete-server'),
        content: tr('are-you-sure-you-want-to-delete-this-server'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('cancel'),
                  style: TextStyle(color: Theme.of(ctx).colorScheme.primary))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeServer(server);
            },
            child: Text(tr('delete'),
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _removeServer(String server) {
    setState(() {
      servers.remove(server);
      serverPingTimes.remove(server);
      if (serversManage.selectedServer == server)
        serversManage.selectServer("#Auto Server");
    });
    _saveServers();
  }

  void _shareServer(String server) => Share.share(server);
  void _editServer(String server) {
    int index = servers.indexOf(server);
    if (index == -1) return;
    final ctrl = TextEditingController(text: servers[index]);
    showDialog(
      context: context,
      builder: (ctx) => AppDialogs.buildDialog(
        context: ctx,
        title: tr('edit-server'),
        contentWidget: TextField(
          controller: ctrl,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
              hintText: 'Enter server configuration',
              border: InputBorder.none,
              hintStyle: TextStyle(
                  color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.5))),
          style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('cancel'),
                  style: TextStyle(color: Theme.of(ctx).colorScheme.primary))),
          TextButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                setState(() => servers[index] = ctrl.text);
                _saveServers();
              }
              Navigator.pop(ctx);
            },
            child: Text(tr('save'),
                style: TextStyle(color: Theme.of(ctx).colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _pingServer(String server) async {
    if (server.startsWith('http') || server.startsWith('freedom-guard')) {
      if (mounted) setState(() => serverPingTimes[server] = null);
      await _savePingTimes();
      return;
    }
    setState(() => serverPingTimes[server] = null);
    try {
      int result = await serversManage.pingC(server);
      if (mounted) setState(() => serverPingTimes[server] = result);
      await _savePingTimes();
    } catch (e) {
      if (mounted) setState(() => serverPingTimes[server] = -1);
      await _savePingTimes();
    }
  }

  Future<void> _pingAllServers() async {
    setState(() => isPingingAll = true);
    int batchSize = 5;
    try {
      for (int i = 0; i < servers.length; i += batchSize) {
        int end =
            (i + batchSize < servers.length) ? i + batchSize : servers.length;
        List<String> batch = servers.sublist(i, end);
        await Future.wait(batch.map((s) => _pingServer(s)));
      }
    } finally {
      if (mounted) setState(() => isPingingAll = false);
    }
  }

  void _toggleSortByPing() {
    setState(() => sortByPing = !sortByPing);
    _applyFiltersAndSort();
  }

  void _cycleViewMode() {
    setState(() =>
        viewMode = viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list);
    SettingsApp().setValue("viewMode", viewMode.name);
  }

  void _showAddServerDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (ctx) => AppDialogs.buildDialog(
        context: ctx,
        title: tr('add-server'),
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: serverController,
              decoration: InputDecoration(
                  hintText: tr('enter-server-config'),
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5))),
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildIconButton(
                    icon: Icons.content_paste,
                    tooltip: 'Paste from clipboard',
                    onPressed: () {
                      Navigator.pop(context);
                      _addFromClipboard();
                    }),
                _buildIconButton(
                    icon: Icons.folder_open,
                    tooltip: 'Import from file',
                    onPressed: () => _importConfigFromFile()),
                _buildIconButton(
                    icon: Icons.build_rounded,
                    tooltip: 'Add Manual Config',
                    onPressed: () async {
                      String? config = await showManualConfigDialog(ctx);
                      if (config != null) _addServer(config);
                    }),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('cancel'),
                  style: TextStyle(color: Theme.of(ctx).colorScheme.primary))),
          TextButton(
              onPressed: () {
                _addServer(serverController.text);
                Navigator.pop(ctx);
              },
              child: Text(tr('add'),
                  style: TextStyle(color: Theme.of(ctx).colorScheme.primary))),
        ],
      ),
    );
  }

  void _importConfigFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['txt', 'conf']);
      if (result == null || result.files.single.path == null) return;
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      if (path.extension(file.path).toLowerCase() == '.conf') {
        _addServer('wire:::\n$content');
      } else {
        List<String> serversFromFile = content
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        for (String server in serversFromFile) _addServer(server);
      }
      LogOverlay.showLog('File imported successfully.');
    } catch (_) {
      LogOverlay.showLog('Error importing file.');
    }
  }

  void _addFromClipboard() async {
    try {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      String? text = data?.text?.trim();
      if (text == null || text.isEmpty) {
        LogOverlay.showLog('Clipboard is empty.');
        return;
      }
      if (text.startsWith('[Interface]')) {
        _addServer('wire:::\n$text');
      } else {
        List<String> serverList = text
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        for (String server in serverList) _addServer(server);
      }
    } catch (_) {
      LogOverlay.showLog('Error reading clipboard.');
    }
  }

  void _removeAllServers() {
    showDialog(
      context: context,
      builder: (ctx) => AppDialogs.buildDialog(
        context: ctx,
        title: tr('remove-all-servers'),
        content: tr('are-you-sure-you-want-to-delete-all-servers'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('cancel'),
                  style: TextStyle(color: Theme.of(ctx).colorScheme.primary))),
          TextButton(
            onPressed: () {
              setState(() {
                servers.clear();
                serverPingTimes.clear();
                serversManage.selectServer("#Auto Server");
              });
              _saveServers();
              Navigator.pop(ctx);
            },
            child: Text(tr('delete'),
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _removeServersWithoutPing() {
    showDialog(
      context: context,
      builder: (ctx) => AppDialogs.buildDialog(
        context: ctx,
        title: tr('remove-servers-without-ping'),
        content: tr('are-you-sure-you-want-to-delete-servers-without-ping'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('cancel'),
                  style: TextStyle(color: Theme.of(ctx).colorScheme.primary))),
          TextButton(
            onPressed: () {
              setState(() {
                List<String> toRemove = servers.where((s) {
                  int? ping = serverPingTimes[s];
                  bool unreachable = ping == -1;
                  bool isHttp =
                      s.startsWith('http://') || s.startsWith('https://');
                  bool isFreedom = s.startsWith('freedom-guard://');
                  bool emptyConfigOrMode =
                      s.split('#')[0].isEmpty || s.startsWith("mode=");
                  return unreachable &&
                      !isHttp &&
                      !isFreedom &&
                      !emptyConfigOrMode;
                }).toList();
                if (toRemove.isNotEmpty) {
                  servers.removeWhere((s) => toRemove.contains(s));
                  serverPingTimes.removeWhere((k, _) => toRemove.contains(k));
                  if (!servers.contains(serversManage.oldServers()))
                    serversManage.selectServer('#Auto Server');
                  _saveServers();
                }
              });
              Navigator.pop(ctx);
            },
            child: Text(tr('delete'),
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showAppBarOptions(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildBottomSheet(
        children: [
          ListTile(
            leading:
                Icon(Icons.refresh, color: Theme.of(ctx).colorScheme.primary),
            title: Text(
              tr('refresh'),
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
            ),
            onTap: () {
              Navigator.pop(ctx);
              _refreshSubscriptions();
            },
          ),
          ListTile(
            leading: Icon(Icons.vpn_key_rounded,
                color: Theme.of(ctx).colorScheme.secondary),
            title: Text(
              'Encrypt / Decrypt',
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
            ),
            onTap: () {
              Navigator.pop(ctx);
              showEncryptDecryptDialog(ctx);
            },
          ),
          ListTile(
            leading: Icon(Icons.signal_wifi_bad,
                color: Theme.of(ctx).colorScheme.error),
            title: Text(
              tr('remove-servers-without-ping'),
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
            onTap: () {
              Navigator.pop(ctx);
              _removeServersWithoutPing();
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_forever,
                color: Theme.of(ctx).colorScheme.error),
            title: Text(
              tr('remove-all-servers'),
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
            onTap: () {
              Navigator.pop(ctx);
              _removeAllServers();
            },
          ),
        ],
      ),
    );
  }

  void _showServerOptions(BuildContext ctx, String server) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildBottomSheet(
        children: [
          ListTile(
            leading: Icon(Icons.edit, color: Theme.of(ctx).colorScheme.primary),
            title: Text(tr('edit'),
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
            onTap: () {
              Navigator.pop(ctx);
              _editServer(server);
            },
          ),
          if (server.startsWith('freedom-guard://') ||
              server.startsWith('http'))
            ListTile(
                leading: Icon(Icons.rocket_launch,
                    color: Theme.of(ctx).colorScheme.primary),
                title: Text('CFG',
                    style:
                        TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
                onTap: () {
                  settings.setValue('selectedSubLink', server);
                  Navigator.push(
                      ctx, MaterialPageRoute(builder: (ctx) => CFGPage()));
                }),
          ListTile(
              leading:
                  Icon(Icons.share, color: Theme.of(ctx).colorScheme.primary),
              title: Text(tr('share'),
                  style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(ctx);
                _shareServer(server);
              }),
          ListTile(
            leading:
                Icon(Icons.qr_code, color: Theme.of(ctx).colorScheme.primary),
            title: Text(tr('qr-code'),
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
            onTap: () {
              Navigator.pop(ctx);
              showQRCode(ctx, server);
            },
          ),
          ListTile(
            leading: Icon(Icons.volunteer_activism,
                color: Theme.of(ctx).colorScheme.primary),
            title: Text(tr('donate'),
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
            onTap: () {
              Navigator.pop(ctx);
              donateCONFIG(server);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Theme.of(ctx).colorScheme.error),
            title: Text(tr('delete'),
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            onTap: () {
              Navigator.pop(ctx);
              _confirmRemoveServer(server);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPingIndicator(int? ping, BuildContext ctx, String server) {
    ThemeData theme = Theme.of(ctx);
    if (server.startsWith('http')) {
      return _buildLabel(theme, 'SUB', theme.colorScheme.secondary);
    } else if (server.startsWith('freedom-guard')) {
      return _buildLabel(theme, 'SUB (FG)', theme.colorScheme.secondary);
    } else if (server.split('#')[0].startsWith("mode=") ||
        server.split("#")[0].isEmpty) {
      return _buildLabel(theme, 'Mode', theme.colorScheme.primary);
    } else if (ping == null) {
      return _buildLabel(
          theme, 'Not Tested', theme.colorScheme.onSurface.withOpacity(0.7));
    } else if (ping == -1) {
      return _buildLabel(theme, '-1', theme.colorScheme.error);
    }

    Color color = ping < 200
        ? Colors.green
        : ping < 500
            ? Colors.orange
            : Colors.red;
    IconData icon = ping < 200
        ? Icons.signal_cellular_4_bar_outlined
        : ping < 500
            ? Icons.signal_cellular_alt_2_bar
            : Icons.signal_cellular_alt_1_bar;
    String protocol = server.contains('://')
        ? server.split('://')[0].toUpperCase()
        : 'Unknown';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (viewMode == ViewMode.list) Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Flexible(
          fit: FlexFit.loose,
          child: (viewMode == ViewMode.list)
              ? _buildLabel(
                  theme,
                  '$protocol • ${ping}ms',
                  color,
                  bold: true,
                )
              : _buildLabel(
                  theme,
                  '${ping}ms',
                  color,
                  bold: true,
                ),
        ),
      ],
    );
  }

  Widget _buildLabel(ThemeData theme, String text, Color color,
      {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 0.8),
      ),
      child: Text(
        text,
        textDirection:
            getDir() == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
        style: TextStyle(
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildBottomSheet({required List<Widget> children}) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.1))),
          child: SafeArea(
              child:
                  Column(mainAxisSize: MainAxisSize.min, children: children)),
        ),
      ),
    );
  }

  Widget _buildIconButton(
      {required IconData icon,
      required String tooltip,
      required VoidCallback onPressed}) {
    return IconButton(
      icon: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
          padding: const EdgeInsets.all(8)),
    );
  }

  Widget _buildServerItem(String server) {
    ThemeData theme = Theme.of(context);
    bool isSelected = multiSelectMode && selectedServers.contains(server);
    bool selected = serversManage.selectedServer == server;
    int? ping = serverPingTimes[server];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected || isSelected
                    ? theme.colorScheme.primary.withOpacity(0.3)
                    : theme.colorScheme.onSurface.withOpacity(0.1),
                width: 2),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                if (multiSelectMode) {
                  setState(() {
                    if (selectedServers.contains(server)) {
                      selectedServers.remove(server);
                    } else {
                      selectedServers.add(server);
                    }
                  });
                } else {
                  await serversManage.selectServer(server);
                  if (mounted) setState(() {});
                }
              },
              onLongPress: () {
                setState(() {
                  multiSelectMode = true;
                  selectedServers.add(server);
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(getNameByConfig(server),
                            style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: theme.colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        _buildPingIndicator(ping, context, server),
                      ],
                    ),
                  ),
                  _buildIconButton(
                      icon: Icons.network_check,
                      tooltip: 'Ping Server',
                      onPressed: () => _pingServer(server)),
                  _buildIconButton(
                      icon: Icons.more_vert,
                      tooltip: 'Options',
                      onPressed: () => _showServerOptions(context, server)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    IconData viewIcon = viewMode == ViewMode.list ? Icons.list_alt : Icons.apps;
    return Directionality(
        textDirection:
            getDir() == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
            extendBody: true,
            appBar: AppBar(
              backgroundColor: theme.colorScheme.primary,
              elevation: 0,
              title: multiSelectMode
                  ? Text('${selectedServers.length} selected',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary))
                  : Text(tr('manage-servers-page'),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary)),
              leading: multiSelectMode
                  ? IconButton(
                      icon:
                          Icon(Icons.close, color: theme.colorScheme.onPrimary),
                      onPressed: () {
                        setState(() {
                          multiSelectMode = false;
                          selectedServers.clear();
                        });
                      },
                    )
                  : null,
              actions: multiSelectMode
                  ? [
                      IconButton(
                        icon: Icon(Icons.network_check,
                            color: theme.colorScheme.onPrimary),
                        tooltip: 'Ping Selected',
                        onPressed: selectedServers.isEmpty
                            ? null
                            : () async {
                                setState(() => isPingingAll = true);
                                try {
                                  await Future.wait(selectedServers
                                      .map((s) => _pingServer(s)));
                                } finally {
                                  if (mounted)
                                    setState(() => isPingingAll = false);
                                }
                              },
                      ),
                      IconButton(
                        icon: Icon(Icons.share,
                            color: theme.colorScheme.onPrimary),
                        tooltip: 'Share Selected',
                        onPressed: selectedServers.isEmpty
                            ? null
                            : () {
                                Share.share(selectedServers.join('\n'));
                              },
                      ),
                      IconButton(
                        icon:
                            Icon(Icons.delete, color: theme.colorScheme.error),
                        tooltip: 'Delete Selected',
                        onPressed: selectedServers.isEmpty
                            ? null
                            : () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AppDialogs.buildDialog(
                                    context: ctx,
                                    title: tr('delete-servers'),
                                    content: tr(
                                        'are-you-sure-you-want-to-delete-selected-servers'),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: Text(tr('cancel'),
                                              style: TextStyle(
                                                  color: theme
                                                      .colorScheme.primary))),
                                      TextButton(
                                          onPressed: () {
                                            setState(() {
                                              servers.removeWhere((s) =>
                                                  selectedServers.contains(s));
                                              serverPingTimes.removeWhere((k,
                                                      _) =>
                                                  selectedServers.contains(k));
                                              selectedServers.clear();
                                              multiSelectMode = false;
                                            });
                                            _saveServers();
                                            Navigator.pop(ctx);
                                          },
                                          child: Text(tr('delete'),
                                              style: TextStyle(
                                                  color: theme
                                                      .colorScheme.error))),
                                    ],
                                  ),
                                );
                              },
                      ),
                    ]
                  : [
                      IconButton(
                        icon: isPingingAll
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.onPrimary))
                            : Icon(Icons.network_check,
                                color: theme.colorScheme.onPrimary),
                        tooltip: 'Ping All',
                        onPressed: isPingingAll ? null : _pingAllServers,
                      ),
                      IconButton(
                        icon: Icon(Icons.sort,
                            color: sortByPing
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.onPrimary),
                        tooltip: 'Sort by Ping',
                        onPressed: _toggleSortByPing,
                      ),
                      IconButton(
                          icon: Icon(Icons.add,
                              color: theme.colorScheme.onPrimary),
                          tooltip: 'Add Server',
                          onPressed: () => _showAddServerDialog(context)),
                      IconButton(
                          icon: Icon(Icons.more_vert,
                              color: theme.colorScheme.onPrimary),
                          tooltip: 'More Options',
                          onPressed: () => _showAppBarOptions(context)),
                    ],
            ),
            body: RefreshIndicator(
                onRefresh: () => _refreshSubscriptions(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.1),
                          theme.colorScheme.secondary.withOpacity(0.1)
                        ]),
                  ),
                  child: isLoading
                      ? Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: theme.colorScheme.surface
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.1))),
                                child: CircularProgressIndicator(
                                    color: theme.colorScheme.primary),
                              ),
                            ),
                          ),
                        )
                      : Column(children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 10, sigmaY: 10),
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: theme.colorScheme.surface
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                                color: theme
                                                    .colorScheme.onSurface
                                                    .withOpacity(0.1))),
                                        child: TextField(
                                          controller: searchController,
                                          decoration: InputDecoration(
                                              hintText: tr('search-servers'),
                                              prefixIcon: Icon(Icons.search,
                                                  color: theme
                                                      .colorScheme.primary),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 16),
                                              hintStyle: TextStyle(
                                                  color: theme
                                                      .colorScheme.onSurface
                                                      .withOpacity(0.5))),
                                          style: TextStyle(
                                              color:
                                                  theme.colorScheme.onSurface),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: theme.colorScheme.surface
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.1))),
                                      child: IconButton(
                                        icon: Icon(viewIcon,
                                            color: theme.colorScheme.primary),
                                        tooltip: 'View Mode',
                                        onPressed: _cycleViewMode,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: filteredServers.isEmpty
                                ? Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 10, sigmaY: 10),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                              color: theme.colorScheme.surface
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                  color: theme
                                                      .colorScheme.onSurface
                                                      .withOpacity(0.1))),
                                          child: Text('No servers found!',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                      color: theme
                                                          .colorScheme.onSurface
                                                          .withOpacity(0.6))),
                                        ),
                                      ),
                                    ),
                                  )
                                : viewMode == ViewMode.list
                                    ? ListView.builder(
                                        padding: const EdgeInsets.only(
                                            bottom: 80, left: 16, right: 16),
                                        itemCount: filteredServers.length,
                                        itemBuilder: (ctx, idx) =>
                                            _buildServerItem(
                                                filteredServers[idx]),
                                      )
                                    : GridView.builder(
                                        padding: const EdgeInsets.only(
                                            bottom: 80, left: 16, right: 16),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 2,
                                                childAspectRatio: 1.2,
                                                crossAxisSpacing: 16,
                                                mainAxisSpacing: 16),
                                        itemCount: filteredServers.length,
                                        itemBuilder: (ctx, idx) =>
                                            _buildServerItem(
                                                filteredServers[idx]),
                                      ),
                          ),
                        ]),
                ))));
  }
}
