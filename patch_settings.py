"""
patch_settings.py — Add or remove nen-contract hook entries in ~/.claude/settings.json

Usage:
  python patch_settings.py install
  python patch_settings.py uninstall
"""
import json, os, shutil, sys, tempfile

def get_paths():
    user = os.environ.get('USERPROFILE') or os.path.expanduser('~')
    settings_path = os.path.join(user, '.claude', 'settings.json')
    nen_cmd = 'python ' + os.path.join(user, '.claude', 'hooks', 'validate_contract.py')
    return settings_path, nen_cmd

def load(settings_path):
    if os.path.exists(settings_path):
        with open(settings_path, encoding='utf-8') as f:
            return json.load(f)
    return {}

def save(settings_path, data):
    dir_ = os.path.dirname(settings_path) or '.'
    os.makedirs(dir_, exist_ok=True)
    with tempfile.NamedTemporaryFile('w', dir=dir_, delete=False, suffix='.tmp', encoding='utf-8') as tmp:
        json.dump(data, tmp, indent=2)
        tmp_path = tmp.name
    shutil.move(tmp_path, settings_path)

def install():
    settings_path, nen_cmd = get_paths()
    data = load(settings_path)
    hooks = data.setdefault('hooks', {})
    post = hooks.setdefault('PostToolUse', [])
    for matcher in ('Write', 'Edit'):
        entry = next((e for e in post if e.get('matcher') == matcher), None)
        if entry is None:
            entry = {'matcher': matcher, 'hooks': []}
            post.append(entry)
        existing = [h.get('command') for h in entry.get('hooks', [])]
        if nen_cmd not in existing:
            entry['hooks'].append({'type': 'command', 'command': nen_cmd})
    save(settings_path, data)
    print('settings.json patched — nen-contract hook registered.')

def uninstall():
    settings_path, nen_cmd = get_paths()
    data = load(settings_path)
    post = data.get('hooks', {}).get('PostToolUse', [])
    for entry in post:
        entry['hooks'] = [h for h in entry.get('hooks', []) if h.get('command') != nen_cmd]
    save(settings_path, data)
    print('settings.json updated — nen-contract hook removed.')

if __name__ == '__main__':
    if len(sys.argv) < 2 or sys.argv[1] not in ('install', 'uninstall'):
        print('Usage: python patch_settings.py install|uninstall')
        sys.exit(1)
    if sys.argv[1] == 'install':
        install()
    else:
        uninstall()
