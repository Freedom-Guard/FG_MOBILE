import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  bool isHttps = true;
  bool isSearchFocused = false;
  List<String> _searchSuggestions = [];
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          _urlController.text = url;
          setState(() {
            isLoading = true;
            isHttps = url.startsWith('https');
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
        onPageFinished: (_) {
          setState(() {
            isLoading = false;
            isSearchFocused = false;
            _searchSuggestions.clear();
          });
          FocusScope.of(context).unfocus();
        },
      ));
    _loadPrefs();
    _searchFocusNode.addListener(() {
      setState(() {
        isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
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
        if (!url.contains(".") && !url.contains(" ")) {
          url = "https://duckduckgo.com/?q=$url";
        } else {
          url = "https://$url";
        }
      }
      if (url.startsWith("http://"))
        url = url.replaceFirst("http://", "https://");
      final fixedUrl = url;
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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bookmarks',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: isDarkMode ? Colors.white70 : Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
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
                      leading: Icon(Icons.bookmark_border,
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
      builder: (_) => Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.bookmark_add_outlined,
                  color: isDarkMode ? Colors.white70 : Colors.black54),
              title: Text('Add Bookmark',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _addBookmark();
              },
            ),
            ListTile(
              leading: Icon(Icons.bookmarks_outlined,
                  color: isDarkMode ? Colors.white70 : Colors.black54),
              title: Text('Show Bookmarks',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _showBookmarks();
              },
            ),
            ListTile(
              leading: Icon(
                  isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                  color: isDarkMode ? Colors.white70 : Colors.black54),
              title: Text('Toggle Theme',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _toggleTheme();
              },
            ),
            ListTile(
              leading: Icon(Icons.share_outlined,
                  color: isDarkMode ? Colors.white70 : Colors.black54),
              title: Text('Share Page',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(context);
                final url = await _controller.currentUrl();
                if (url != null) {
                  Share.share(url);
                }
              },
            ),
          ],
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
    final bgColor = isDarkMode ? Colors.black : Colors.white;
    final fgColor = isDarkMode ? Colors.white : Colors.black;
    final inputColor = isDarkMode ? Colors.grey[850] : Colors.grey[200];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        elevation: 0,
        title: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: isSearchFocused
              ? MediaQuery.of(context).size.width * 0.8
              : MediaQuery.of(context).size.width,
          child: Row(
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
                    prefixIcon: Icon(
                        isHttps ? Icons.lock_outline : Icons.lock_open_outlined,
                        color: isHttps ? Colors.green : Colors.red),
                  ),
                  onSubmitted: (_) => _goToUrl(),
                  onTap: () {
                    setState(() {
                      isSearchFocused = true;
                      _urlController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _urlController.text.length);
                    });
                  },
                  onChanged: (value) => _fetchSearchSuggestions(value),
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onEditingComplete: _goToUrl,
                ),
              ),
              if (!isSearchFocused) ...[
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.refresh_sharp, color: fgColor),
                  onPressed: () => _controller.reload(),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert_rounded, color: fgColor),
                  onPressed: _showMoreOptions,
                ),
              ],
            ],
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
            WebViewWidget(controller: _controller),
            if (isLoading)
              Center(
                child: CircularProgressIndicator(
                  color: fgColor,
                  backgroundColor: fgColor.withOpacity(0.1),
                ),
              ),
            if (_searchSuggestions.isNotEmpty && isSearchFocused)
              Positioned(
                top: 0,
                left: 16,
                right: 16,
                child: Material(
                  color: isDarkMode ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  elevation: 4,
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _searchSuggestions[index];
                        return ListTile(
                          title: Text(
                            suggestion,
                            style: TextStyle(color: fgColor),
                          ),
                          onTap: () {
                            _urlController.text = suggestion;
                            _goToUrl();
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: () async {
                  if (await _controller.canGoBack()) _controller.goBack();
                  FocusScope.of(context).unfocus();
                },
                color: fgColor,
                tooltip: 'Back',
              ),
              _buildNavButton(
                icon: Icons.home_rounded,
                onPressed: () {
                  _controller
                      .loadRequest(Uri.parse('https://start.duckduckgo.com'));
                  _urlController.text = 'https://start.duckduckgo.com';
                  FocusScope.of(context).unfocus();
                },
                color: fgColor,
                tooltip: 'Home',
              ),
              _buildNavButton(
                icon: Icons.arrow_forward_ios_rounded,
                onPressed: () async {
                  if (await _controller.canGoForward()) _controller.goForward();
                  FocusScope.of(context).unfocus();
                },
                color: fgColor,
                tooltip: 'Forward',
              ),
            ],
          ),
        ),
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
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color.fromARGB(62, 22, 121, 214).withOpacity(0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isDarkMode ? Colors.white : Colors.black,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
