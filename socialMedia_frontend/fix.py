import os

def replace_in_file(filepath, old, new):
    if not os.path.exists(filepath): return
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    if old in content:
        content = content.replace(old, new)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

base = r'C:\Users\ozges\OneDrive\Dokumente\Spot\frontend\lib'

# 1. Fix MyApp build method in main.dart
replace_in_file(os.path.join(base, 'main.dart'), 'Widget build(BuildContext context, WidgetRef ref)', 'Widget build(BuildContext context)')
replace_in_file(os.path.join(base, 'main.dart'), 'class MyApp extends ConsumerWidget', 'class MyApp extends StatelessWidget')
replace_in_file(os.path.join(base, 'main.dart'), 'const ProviderScope', 'ProviderScope')
replace_in_file(os.path.join(base, 'main.dart'), "import './navigation/app_navigator.dart';", "")

# 3. Add riverpod to all widgets that use WidgetRef
def add_riverpod_import(filepath):
    if not os.path.exists(filepath): return
    with open(filepath, 'r', encoding='utf-8') as f:
        c = f.read()
    if 'ConsumerStatefulWidget' in c or 'ConsumerWidget' in c or 'WidgetRef' in c:
        if 'flutter_riverpod' not in c:
            c = "import 'package:flutter_riverpod/flutter_riverpod.dart';\n" + c
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(c)

    # Convert StatelessWidget back if it's not actually using WidgetRef
    if 'ConsumerWidget' in c and 'WidgetRef ref' not in c:
        c = c.replace('ConsumerWidget', 'StatelessWidget')
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(c)
            
    # Fix ConsumerStatefulWidget without ConsumerState
    if 'ConsumerStatefulWidget' in c:
        c = c.replace('State<', 'ConsumerState<')
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(c)

for root, _, files in os.walk(base):
    for f in files:
        if f.endswith('.dart'):
            add_riverpod_import(os.path.join(root, f))
