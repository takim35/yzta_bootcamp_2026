import os

base = r'C:\Users\ozges\OneDrive\Dokumente\Spot\frontend\lib'
for root, _, files in os.walk(base):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                c = file.read()
            changed = False
            if 'Widget build(BuildContext context, WidgetRef ref)' in c:
                if 'extends StatelessWidget' in c:
                    c = c.replace('extends StatelessWidget', 'extends ConsumerWidget')
                    changed = True
                if 'flutter_riverpod' not in c:
                    c = "import 'package:flutter_riverpod/flutter_riverpod.dart';\n" + c
                    changed = True
            
            # fix app navigator error where it extends StatefulWidget instead of ConsumerStatefulWidget
            if 'class AppNavigator extends StatefulWidget' in c:
                c = c.replace('class AppNavigator extends StatefulWidget', 'class AppNavigator extends ConsumerStatefulWidget')
                c = c.replace('State<AppNavigator>', 'ConsumerState<AppNavigator>')
                changed = True
                
            if changed:
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(c)
