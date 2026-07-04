import os

base = r'C:\Users\ozges\OneDrive\Dokumente\Spot\frontend\lib'

# Fix ConsumerConsumerState
for root, _, files in os.walk(base):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as f_obj:
                c = f_obj.read()
            if 'ConsumerConsumerState' in c:
                c = c.replace('ConsumerConsumerState', 'ConsumerState')
                with open(path, 'w', encoding='utf-8') as f_obj:
                    f_obj.write(c)
            # Fix duplicate ProviderScope in main.dart
            if f == 'main.dart' and 'const ProviderScope' in c:
                c = c.replace('const ProviderScope', 'ProviderScope')
                with open(path, 'w', encoding='utf-8') as f_obj:
                    f_obj.write(c)

# Add global providers
def add_global_provider(path, class_name, provider_name):
    if not os.path.exists(path): return
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()
    if f'final {provider_name} =' not in c:
        if 'import \'package:flutter_riverpod/flutter_riverpod.dart\';' not in c:
            c = "import 'package:flutter_riverpod/flutter_riverpod.dart';\n" + c
        c = c.replace(f'class {class_name} extends ChangeNotifier', f'final {provider_name} = ChangeNotifierProvider((ref) => {class_name}());\n\nclass {class_name} extends ChangeNotifier')
        with open(path, 'w', encoding='utf-8') as f:
            f.write(c)

add_global_provider(os.path.join(base, 'features', 'create_post', 'presentation', 'providers', 'create_post_provider.dart'), 'CreatePostProvider', 'createPostProvider')
add_global_provider(os.path.join(base, 'features', 'profile', 'presentation', 'providers', 'profile_provider.dart'), 'ProfileProvider', 'profileProvider')

# Fix Consumer<CreatePostProvider>
create_post_screen = os.path.join(base, 'features', 'create_post', 'presentation', 'screens', 'create_post_screen.dart')
if os.path.exists(create_post_screen):
    with open(create_post_screen, 'r', encoding='utf-8') as f:
        c = f.read()
    c = c.replace('Consumer<CreatePostProvider>(', 'Consumer(')
    c = c.replace('builder: (context, provider, _)', 'builder: (context, ref, _) {\n        final provider = ref.watch(createPostProvider);')
    with open(create_post_screen, 'w', encoding='utf-8') as f:
        f.write(c)
