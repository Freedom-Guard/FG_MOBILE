import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';

class FreedomBrowser extends StatefulWidget {
  @override
  State<FreedomBrowser> createState() => _FreedomBrowserState();
}

class _FreedomBrowserState extends State<FreedomBrowser> {
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController();
  List<String> _bookmarks = [];
  List<String> _history = [];
  bool isLoading = true;
  bool isDarkMode = false;
  bool isHttps = true;
  bool isSearchFocused = false;
  List<String> _searchSuggestions = [];
  final FocusNode _searchFocusNode = FocusNode();
  double _progress = 0.0;
  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (progress) {
          setState(() {
            _progress = progress / 100;
          });
        },
        onPageStarted: (url) {
          _urlController.text = url;
          setState(() {
            isLoading = true;
            isHttps = url.startsWith('https');
            _progress = 0.0;
          });
        },
        onNavigationRequest: (request) {
          setState(() {
            _urlController.text = request.url;
            isSearchFocused = false;
            _searchSuggestions.clear();
          });
          FocusScope.of(context).unfocus();
          return NavigationDecision.navigate;
        },
        onPageFinished: (url) {
          setState(() {
            isLoading = false;
            isSearchFocused = false;
            _searchSuggestions.clear();
            _progress = 1.0;
          });
          if (!_history.contains(url)) {
            _history.add(url);
            _savePrefs();
          }
          FocusScope.of(context).unfocus();
        },
        onWebResourceError: (error) {
          setState(() {
            isLoading = false;
          });
          LogOverlay.showLog('Error loading page: ${error.description}');
        },
      ));
    _loadPrefs();
    _searchFocusNode.addListener(() {
      setState(() {
        isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  Future<void> clearEverything() async {
    await _controller.clearCache();
    await _controller.clearLocalStorage();
    _history.clear();
    _bookmarks.clear();
    _savePrefs();
    LogOverlay.showLog('All data cleared');
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUrl =
        prefs.getString('last_url') ?? 'https://start.duckduckgo.com';
    _bookmarks = prefs.getStringList('bookmarks') ?? [];
    _history = prefs.getStringList('history') ?? [];
    isDarkMode = prefs.getBool('dark_mode') ?? false;
    _urlController.text = lastUrl;
    _controller.loadRequest(Uri.parse(lastUrl));
    setState(() {});
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('bookmarks', _bookmarks);
    prefs.setStringList('history', _history);
    prefs.setBool('dark_mode', isDarkMode);
    final currentUrl = await _controller.currentUrl();
    if (currentUrl != null) prefs.setString('last_url', currentUrl);
  }

  Future<void> _fetchSearchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => _searchSuggestions.clear());
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('https://ac.duckduckgo.com/ac?q=$query&type=list'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> suggestions = jsonDecode(response.body)[1];
        setState(() {
          _searchSuggestions = suggestions.cast<String>();
        });
      }
    } catch (e) {
      setState(() => _searchSuggestions.clear());
    }
  }

  void _goToUrl() {
    var url = _urlController.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        isSearchFocused = false;
        _searchSuggestions.clear();
      });
      FocusScope.of(context).unfocus();
      if (!url.startsWith("http://") && !url.startsWith("https://")) {
        if (!url.contains(".") || url.contains(" ")) {
          url = "https://duckduckgo.com/?q=${Uri.encodeComponent(url)}";
        } else {
          url = "https://$url";
        }
      }
      if (url.startsWith("http://")) {
        url = url.replaceFirst("http://", "https://");
      }
      _controller.loadRequest(Uri.parse(url));
    }
  }

  void _addBookmark() async {
    final url = await _controller.currentUrl();
    if (url != null && !_bookmarks.contains(url)) {
      setState(() => _bookmarks.add(url));
      _savePrefs();
      LogOverlay.showLog('Bookmark added');
    }
  }

  void _removeBookmark(String url) {
    setState(() => _bookmarks.remove(url));
    _savePrefs();
    LogOverlay.showLog('Bookmark removed');
  }

  void showBookmarks() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => _buildGlassModal(
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, controller) => Column(
            children: [
              _buildModalHeader('Bookmarks'),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: _bookmarks.length,
                  itemBuilder: (_, index) {
                    final url = _bookmarks[index];
                    return Dismissible(
                      key: Key(url),
                      background: Container(
                        color: Colors.red.withOpacity(0.7),
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _removeBookmark(url),
                      child: _buildListTile(
                        icon: Icons.bookmark_outline_rounded,
                        title: url,
                        onTap: () {
                          Navigator.pop(context);
                          _controller.loadRequest(Uri.parse(url));
                          _urlController.text = url;
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => _buildGlassModal(
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, controller) => Column(
            children: [
              _buildModalHeader('History'),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: _history.length,
                  itemBuilder: (_, index) {
                    final url = _history[index];
                    return Dismissible(
                      key: Key(url),
                      background: Container(
                        color: Colors.red.withOpacity(0.7),
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        setState(() => _history.remove(url));
                        _savePrefs();
                      },
                      child: _buildListTile(
                        icon: Icons.history_outlined,
                        title: url,
                        onTap: () {
                          Navigator.pop(context);
                          _controller.loadRequest(Uri.parse(url));
                          _urlController.text = url;
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalHeader(String title) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.grey[850]!.withOpacity(0.6)
                : Colors.grey[100]!.withOpacity(0.6),
            border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded,
                    color: isDarkMode ? Colors.white70 : Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon,
          color: isDarkMode ? Colors.white70 : Colors.black54, size: 28),
      title: Text(
        title,
        style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
      tileColor: Colors.transparent,
    );
  }

  void _toggleTheme() {
    setState(() => isDarkMode = !isDarkMode);
    _savePrefs();
  }

  void showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _buildGlassModal(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOptionTile(
                icon: Icons.bookmark_add_outlined,
                title: 'Add Bookmark',
                onTap: () {
                  Navigator.pop(context);
                  _addBookmark();
                },
              ),
              _buildOptionTile(
                icon: Icons.bookmarks_outlined,
                title: 'Show Bookmarks',
                onTap: () {
                  Navigator.pop(context);
                  showBookmarks();
                },
              ),
              _buildOptionTile(
                icon: Icons.history_outlined,
                title: 'Show History',
                onTap: () {
                  Navigator.pop(context);
                  showHistory();
                },
              ),
              _buildOptionTile(
                icon: isDarkMode
                    ? Icons.wb_sunny_outlined
                    : Icons.nightlight_round_outlined,
                title: 'Toggle Theme',
                onTap: () {
                  Navigator.pop(context);
                  _toggleTheme();
                },
              ),
              _buildOptionTile(
                icon: Icons.share_outlined,
                title: 'Share Page',
                onTap: () async {
                  Navigator.pop(context);
                  final url = await _controller.currentUrl();
                  if (url != null) {
                    Share.share(url);
                  }
                },
              ),
              _buildOptionTile(
                icon: Icons.clear_all_outlined,
                title: 'Clear All Data',
                onTap: () {
                  Navigator.pop(context);
                  clearEverything();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon,
          color: isDarkMode ? Colors.white70 : Colors.black54, size: 28),
      title: Text(title,
          style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 16)),
      onTap: onTap,
      tileColor: Colors.transparent,
    );
  }

  Widget _buildGlassModal({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.grey[900]!.withOpacity(0.4)
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border:
                Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _savePrefs();
    _urlController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: isDarkMode
          ? ThemeData.dark().copyWith(
              primaryColor: Colors.blueAccent,
              scaffoldBackgroundColor: Colors.grey[900],
              cardColor: Colors.grey[800],
              textTheme: TextTheme(bodyLarge: TextStyle(color: Colors.white)),
              inputDecorationTheme: InputDecorationTheme(
                fillColor: Colors.grey[800],
              ),
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                backgroundColor: Colors.grey[850],
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.grey[850],
              ),
            )
          : ThemeData.light().copyWith(
              primaryColor: Colors.blue,
              scaffoldBackgroundColor: Colors.white,
              cardColor: Colors.white,
              textTheme: TextTheme(bodyLarge: TextStyle(color: Colors.black87)),
              inputDecorationTheme: InputDecorationTheme(
                fillColor: Colors.grey[200],
              ),
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                backgroundColor: Colors.grey[100],
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.grey[100],
              ),
            ),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final bgColor = theme.scaffoldBackgroundColor;
          final fgColor = theme.textTheme.bodyLarge!.color!;
          final inputColor = theme.inputDecorationTheme.fillColor!;
          return WillPopScope(
            onWillPop: () async {
              if (await _controller.canGoBack()) {
                _controller.goBack();
                return false;
              }
              await clearEverything();
              return true;
            },
            child: Scaffold(
              backgroundColor: bgColor,
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: AppBar(
                      backgroundColor:
                          theme.appBarTheme.backgroundColor?.withOpacity(0.4),
                      elevation: 0,
                      title: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: isSearchFocused
                            ? MediaQuery.of(context).size.width * 0.75
                            : MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: inputColor.withOpacity(0.6),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _urlController,
                                style: TextStyle(color: fgColor, fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'Enter URL or search',
                                  hintStyle: TextStyle(
                                      color: fgColor.withOpacity(0.5),
                                      fontSize: 16),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 14),
                                  border: InputBorder.none,
                                  prefixIcon: Icon(
                                      isHttps
                                          ? Icons.lock_rounded
                                          : Icons.lock_open_rounded,
                                      color: isHttps
                                          ? Colors.greenAccent
                                          : Colors.redAccent),
                                ),
                                onSubmitted: (_) => _goToUrl(),
                                onTap: () {
                                  setState(() {
                                    isSearchFocused = true;
                                    _urlController.selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset:
                                            _urlController.text.length);
                                  });
                                },
                                onChanged: (value) =>
                                    _fetchSearchSuggestions(value),
                                focusNode: _searchFocusNode,
                                textInputAction: TextInputAction.search,
                                onEditingComplete: _goToUrl,
                              ),
                            ),
                            if (!isSearchFocused) ...[
                              SizedBox(width: 8),
                              IconButton(
                                icon:
                                    Icon(Icons.refresh_rounded, color: fgColor),
                                onPressed: () => _controller.reload(),
                              ),
                              IconButton(
                                icon: Icon(Icons.more_vert_rounded,
                                    color: fgColor),
                                onPressed: showMoreOptions,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              body: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    isSearchFocused = false;
                    _searchSuggestions.clear();
                  });
                },
                child: Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () async {
                        _controller.reload();
                      },
                      color: theme.primaryColor,
                      backgroundColor: bgColor,
                      child: WebViewWidget(controller: _controller),
                    ),
                    if (isLoading)
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: fgColor.withOpacity(0.1),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(theme.primaryColor),
                        minHeight: 3,
                      ),
                    if (_searchSuggestions.isNotEmpty && isSearchFocused)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(20)),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Material(
                              color: theme.cardColor.withOpacity(0.4),
                              borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(20)),
                              child: Container(
                                constraints: BoxConstraints(maxHeight: 250),
                                decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color:
                                              Colors.white.withOpacity(0.1))),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  itemCount: _searchSuggestions.length,
                                  itemBuilder: (context, index) {
                                    final suggestion =
                                        _searchSuggestions[index];
                                    return ListTile(
                                      title: Text(
                                        suggestion,
                                        style: TextStyle(
                                            color: fgColor, fontSize: 16),
                                      ),
                                      onTap: () {
                                        _urlController.text = suggestion;
                                        _goToUrl();
                                      },
                                      dense: true,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              bottomNavigationBar: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.bottomNavigationBarTheme.backgroundColor
                          ?.withOpacity(0.4),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.15), width: 1.5),
                    ),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onPressed: () async {
                              if (await _controller.canGoBack())
                                _controller.goBack();
                              FocusScope.of(context).unfocus();
                            },
                            color: fgColor,
                            tooltip: 'Back',
                          ),
                          _buildNavButton(
                            icon: Icons.home_rounded,
                            onPressed: () {
                              _controller.loadRequest(
                                  Uri.parse('https://start.duckduckgo.com'));
                              _urlController.text =
                                  'https://start.duckduckgo.com';
                              FocusScope.of(context).unfocus();
                            },
                            color: fgColor,
                            tooltip: 'Home',
                          ),
                          _buildNavButton(
                            icon: Icons.arrow_forward_ios_rounded,
                            onPressed: () async {
                              if (await _controller.canGoForward())
                                _controller.goForward();
                              FocusScope.of(context).unfocus();
                            },
                            color: fgColor,
                            tooltip: 'Forward',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}
