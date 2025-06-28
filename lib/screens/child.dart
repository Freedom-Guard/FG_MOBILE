import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentalLockPage extends StatefulWidget {
  @override
  _ParentalLockPageState createState() => _ParentalLockPageState();
}

class _ParentalLockPageState extends State<ParentalLockPage> {
  TextEditingController _passCtrl = TextEditingController();
  TextEditingController _confirmCtrl = TextEditingController();
  TextEditingController _enterCtrl = TextEditingController();
  TextEditingController _newSiteCtrl = TextEditingController();
  String? _password;
  bool _isUnlocked = false;
  bool _lockEnabled = false;
  List<String> _sites = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _password = prefs.getString('parent_password');
      _lockEnabled = prefs.getBool('child_lock_enabled') ?? false;
      _sites = prefs.getStringList('blocked_sites') ?? [];
    });
  }

  Future<void> _setPassword() async {
    if (_passCtrl.text.isEmpty || _passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'رمزها مطابقت ندارند یا خالی‌اند');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('parent_password', _passCtrl.text);
    setState(() {
      _password = _passCtrl.text;
      _isUnlocked = true;
      _error = null;
    });
  }

  Future<void> _checkPassword() async {
    if (_enterCtrl.text == _password) {
      setState(() {
        _isUnlocked = true;
        _error = null;
      });
    } else {
      setState(() => _error = 'رمز اشتباه است');
    }
  }

  Future<void> _toggleLock() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _lockEnabled = !_lockEnabled);
    await prefs.setBool('child_lock_enabled', _lockEnabled);
  }

  Future<void> _addSite() async {
    final site = _newSiteCtrl.text.trim();
    if (site.isEmpty || _sites.contains(site)) return;
    setState(() => _sites.add(site));
    _newSiteCtrl.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blocked_sites', _sites);
  }

  Future<void> _removeSite(String site) async {
    setState(() => _sites.remove(site));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blocked_sites', _sites);
  }

  Future<void> _resetPassword() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('parent_password');
    setState(() {
      _password = null;
      _isUnlocked = false;
      _passCtrl.clear();
      _confirmCtrl.clear();
      _enterCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('قفل کودک')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _password == null
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('تنظیم رمز جدید', style: TextStyle(fontSize: 20)),
                SizedBox(height: 16),
                TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(labelText: 'رمز')),
                SizedBox(height: 12),
                TextField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    decoration: InputDecoration(labelText: 'تکرار رمز')),
                if (_error != null) ...[
                  SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: Colors.redAccent)),
                ],
                SizedBox(height: 24),
                ElevatedButton(onPressed: _setPassword, child: Text('ثبت رمز')),
              ])
            : !_isUnlocked
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Text('ورود رمز', style: TextStyle(fontSize: 20)),
                        SizedBox(height: 16),
                        TextField(
                            controller: _enterCtrl,
                            obscureText: true,
                            decoration: InputDecoration(labelText: 'رمز')),
                        if (_error != null) ...[
                          SizedBox(height: 8),
                          Text(_error!,
                              style: TextStyle(color: Colors.redAccent)),
                        ],
                        SizedBox(height: 24),
                        ElevatedButton(
                            onPressed: _checkPassword, child: Text('ورود')),
                      ])
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        SwitchListTile(
                          title: Text('فعال‌سازی قفل کودک'),
                          value: _lockEnabled,
                          onChanged: (_) => _toggleLock(),
                          activeColor: Colors.greenAccent,
                        ),
                        Row(children: [
                          Expanded(
                            child: TextField(
                              controller: _newSiteCtrl,
                              decoration:
                                  InputDecoration(hintText: 'example.com'),
                              onSubmitted: (_) => _addSite(),
                            ),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                              onPressed: _addSite, child: Text('افزودن')),
                        ]),
                        SizedBox(height: 20),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _sites.length,
                            itemBuilder: (_, i) => ListTile(
                              title: Text(_sites[i]),
                              trailing: IconButton(
                                icon:
                                    Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _removeSite(_sites[i]),
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: TextButton(
                            onPressed: _resetPassword,
                            child: Text(
                              'حذف رمز و تنظیم مجدد',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      ]),
      ),
    );
  }
}
