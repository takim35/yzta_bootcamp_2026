import os

base = r'C:\Users\ozges\OneDrive\Dokumente\Spot\frontend\lib'
for root, _, files in os.walk(base):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                c = file.read()
            changed = False
            
            # If a class extends ConsumerState, its build method must be Widget build(BuildContext context)
            # NOT Widget build(BuildContext context, WidgetRef ref)
            if 'extends ConsumerState' in c or 'extends State' in c:
                if 'Widget build(BuildContext context, WidgetRef ref)' in c:
                    c = c.replace('Widget build(BuildContext context, WidgetRef ref)', 'Widget build(BuildContext context)')
                    changed = True

            # Fix the duplicate { in create_post_screen.dart
            if f == 'create_post_screen.dart':
                if 'builder: (context, ref, _) {\n        final provider = ref.watch(createPostProvider); {' in c:
                    c = c.replace('builder: (context, ref, _) {\n        final provider = ref.watch(createPostProvider); {', 'builder: (context, ref, _) {\n        final provider = ref.watch(createPostProvider);')
                    changed = True
                if 'builder: (context, ref, _) {\n        final provider = ref.watch(createPostProvider);\n        {' in c:
                    c = c.replace('builder: (context, ref, _) {\n        final provider = ref.watch(createPostProvider);\n        {', 'builder: (context, ref, _) {\n        final provider = ref.watch(createPostProvider);')
                    changed = True
                    
            if changed:
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(c)
