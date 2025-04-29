import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FreedomBrowser extends StatefulWidget {
  @override
  State<FreedomBrowser> createState() => _FreedomBrowserState();
}

class _FreedomBrowserState extends State<FreedomBrowser> {
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController();
  List<String> _bookmarks = [];
  bool isLoading = true;
  bool isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => isLoading = true),
        onPageFinished: (_) => setState(() => isLoading = false),
      ));
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUrl =
        prefs.getString('last_url') ?? 'https://start.duckduckgo.com';
    _bookmarks = prefs.getStringList('bookmarks') ?? [];
    isDarkMode = prefs.getBool('dark_mode') ?? true;
    _urlController.text = lastUrl;
    _controller.loadRequest(Uri.parse(lastUrl));
    setState(() {});
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('bookmarks', _bookmarks);
    prefs.setBool('dark_mode', isDarkMode);
    final currentUrl = await _controller.currentUrl();
    if (currentUrl != null) prefs.setString('last_url', currentUrl);
  }

  void _goToUrl() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      final fixedUrl = url.startsWith('http') ? url : 'https://$url';
      _controller.loadRequest(Uri.parse(fixedUrl));
    }
  }

  void _addBookmark() async {
    final url = await _controller.currentUrl();
    if (url != null && !_bookmarks.contains(url)) {
      setState(() => _bookmarks.add(url));
      _savePrefs();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bookmark added')),
      );
    }
  }

  void _removeBookmark(String url) {
    setState(() => _bookmarks.remove(url));
    _savePrefs();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bookmark removed')),
    );
  }

  void _showBookmarks() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                'Bookmarks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: _bookmarks.length,
                itemBuilder: (_, index) {
                  final url = _bookmarks[index];
                  return Dismissible(
                    key: Key(url),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 16),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _removeBookmark(url),
                    child: ListTile(
                      leading: Icon(Icons.bookmark,
                          color: isDarkMode ? Colors.white70 : Colors.black54),
                      title: Text(
                        url,
                        style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _controller.loadRequest(Uri.parse(url));
                        _urlController.text = url;
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTheme() {
    setState(() => isDarkMode = !isDarkMode);
    _savePrefs();
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.bookmark_add,
                color: isDarkMode ? Colors.white70 : Colors.black54),
            title: Text('Add Bookmark',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            onTap: () {
              Navigator.pop(context);
              _addBookmark();
            },
          ),
          ListTile(
            leading: Icon(Icons.bookmarks,
                color: isDarkMode ? Colors.white70 : Colors.black54),
            title: Text('Show Bookmarks',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            onTap: () {
              Navigator.pop(context);
              _showBookmarks();
            },
          ),
          ListTile(
            leading: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: isDarkMode ? Colors.white70 : Colors.black54),
            title: Text('Toggle Theme',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            onTap: () {
              Navigator.pop(context);
              _toggleTheme();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _savePrefs();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? Colors.black : Colors.white;
    final fgColor = isDarkMode ? Colors.white : Colors.black;
    final inputColor = isDarkMode ? Colors.grey[850] : Colors.grey[200];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _urlController,
                style: TextStyle(color: fgColor),
                decoration: InputDecoration(
                  hintText: 'Enter URL or search',
                  hintStyle: TextStyle(color: fgColor.withOpacity(0.5)),
                  filled: true,
                  fillColor: inputColor,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon:
                      Icon(Icons.search, color: fgColor.withOpacity(0.5)),
                ),
                onSubmitted: (_) => _goToUrl(),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.arrow_forward, color: fgColor),
              onPressed: _goToUrl,
            ),
            IconButton(
              icon: Icon(Icons.more_vert, color: fgColor),
              onPressed: _showMoreOptions,
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(
                color: fgColor,
                backgroundColor: fgColor.withOpacity(0.1),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: fgColor),
                onPressed: () async {
                  if (await _controller.canGoBack()) _controller.goBack();
                },
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.arrow_forward, color: fgColor),
                onPressed: () async {
                  if (await _controller.canGoForward()) _controller.goForward();
                },
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.home, color: fgColor),
                onPressed: () {
                  _controller
                      .loadRequest(Uri.parse('https://start.duckduckgo.com'));
                  _urlController.text = 'https://start.duckduckgo.com';
                },
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.refresh, color: fgColor),
                onPressed: () => _controller.reload(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
