import os
import re

base_dir = r'C:\Users\ozges\OneDrive\Dokumente\Spot\frontend\lib'

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    rel_path = os.path.relpath(filepath, base_dir)
    depth = rel_path.count(os.sep)
    up = '../' * depth if depth > 0 else './'

    content = content.replace("import 'package:provider/provider.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';")

    # Replace local imports (naively replacing known paths)
    content = content.replace("import '../theme/app_theme.dart';", f"import '{up}core/theme/app_theme.dart';")
    content = content.replace("import '../../theme/app_theme.dart';", f"import '{up}core/theme/app_theme.dart';")
    content = content.replace("import 'theme/app_theme.dart';", f"import '{up}core/theme/app_theme.dart';")
    
    # Models
    content = content.replace("import '../models/post_model.dart';", f"import '{up}features/feed/domain/models/post_model.dart';")
    content = content.replace("import '../../models/post_model.dart';", f"import '{up}features/feed/domain/models/post_model.dart';")
    content = content.replace("import 'models/post_model.dart';", f"import '{up}features/feed/domain/models/post_model.dart';")
    
    content = content.replace("import '../models/user_model.dart';", f"import '{up}features/profile/domain/models/user_model.dart';")
    content = content.replace("import '../../models/user_model.dart';", f"import '{up}features/profile/domain/models/user_model.dart';")
    
    content = content.replace("import '../models/outfit_item_model.dart';", f"import '{up}features/feed/domain/models/outfit_item_model.dart';")
    
    # Providers
    content = content.replace("import '../providers/feed_provider.dart';", f"import '{up}features/feed/presentation/providers/feed_provider.dart';")
    content = content.replace("import '../../providers/feed_provider.dart';", f"import '{up}features/feed/presentation/providers/feed_provider.dart';")
    content = content.replace("import 'providers/feed_provider.dart';", f"import '{up}features/feed/presentation/providers/feed_provider.dart';")

    content = content.replace("import '../providers/create_post_provider.dart';", f"import '{up}features/create_post/presentation/providers/create_post_provider.dart';")
    content = content.replace("import '../../providers/create_post_provider.dart';", f"import '{up}features/create_post/presentation/providers/create_post_provider.dart';")
    content = content.replace("import 'providers/create_post_provider.dart';", f"import '{up}features/create_post/presentation/providers/create_post_provider.dart';")

    content = content.replace("import '../providers/profile_provider.dart';", f"import '{up}features/profile/presentation/providers/profile_provider.dart';")
    content = content.replace("import '../../providers/profile_provider.dart';", f"import '{up}features/profile/presentation/providers/profile_provider.dart';")
    content = content.replace("import 'providers/profile_provider.dart';", f"import '{up}features/profile/presentation/providers/profile_provider.dart';")

    # Screens
    content = content.replace("import '../screens/feed_screen.dart';", f"import '{up}features/feed/presentation/screens/feed_screen.dart';")
    content = content.replace("import 'screens/feed_screen.dart';", f"import '{up}features/feed/presentation/screens/feed_screen.dart';")
    content = content.replace("import '../screens/create_post_screen.dart';", f"import '{up}features/create_post/presentation/screens/create_post_screen.dart';")
    content = content.replace("import '../screens/profile_screen.dart';", f"import '{up}features/profile/presentation/screens/profile_screen.dart';")
    content = content.replace("import '../screens/main_home_screen.dart';", f"import '{up}features/main_home_screen.dart';")
    content = content.replace("import 'screens/main_home_screen.dart';", f"import '{up}features/main_home_screen.dart';")
    
    # Widgets
    content = content.replace("import '../widgets/post_card.dart';", f"import '{up}features/feed/presentation/widgets/post_card.dart';")
    content = content.replace("import '../widgets/shimmer_loading.dart';", f"import '{up}features/feed/presentation/widgets/shimmer_loading.dart';")
    content = content.replace("import '../widgets/empty_state.dart';", f"import '{up}features/feed/presentation/widgets/empty_state.dart';")
    content = content.replace("import '../widgets/like_button.dart';", f"import '{up}features/feed/presentation/widgets/like_button.dart';")
    content = content.replace("import '../widgets/profile_header.dart';", f"import '{up}features/profile/presentation/widgets/profile_header.dart';")
    content = content.replace("import '../widgets/visibility_selector.dart';", f"import '{up}features/create_post/presentation/widgets/visibility_selector.dart';")
    content = content.replace("import '../widgets/outfit_picker.dart';", f"import '{up}features/create_post/presentation/widgets/outfit_picker.dart';")

    # Navigation
    content = content.replace("import 'navigation/app_navigator.dart';", f"import '{up}navigation/app_navigator.dart';")
    content = content.replace("import '../navigation/app_navigator.dart';", f"import '{up}navigation/app_navigator.dart';")

    # Services
    content = content.replace("import '../services/api_service.dart';", f"import '{up}services/api_service.dart';")
    content = content.replace("import '../../services/api_service.dart';", f"import '{up}services/api_service.dart';")
    
    # Riverpod fixes
    content = content.replace("class AppNavigator extends StatefulWidget", "class AppNavigator extends ConsumerStatefulWidget")
    content = content.replace("State<AppNavigator>", "ConsumerState<AppNavigator>")
    
    content = content.replace("class FeedScreen extends StatefulWidget", "class FeedScreen extends ConsumerStatefulWidget")
    content = content.replace("State<FeedScreen>", "ConsumerState<FeedScreen>")
    
    content = content.replace("class CreatePostScreen extends StatefulWidget", "class CreatePostScreen extends ConsumerStatefulWidget")
    content = content.replace("State<CreatePostScreen>", "ConsumerState<CreatePostScreen>")
    
    content = content.replace("class ProfileScreen extends StatefulWidget", "class ProfileScreen extends ConsumerStatefulWidget")
    content = content.replace("State<ProfileScreen>", "ConsumerState<ProfileScreen>")
    
    content = content.replace("class MainHomeScreen extends StatelessWidget", "class MainHomeScreen extends ConsumerWidget")
    content = content.replace("Widget build(BuildContext context) {", "Widget build(BuildContext context, WidgetRef ref) {")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for root, _, files in os.walk(base_dir):
    for f in files:
        if f.endswith('.dart'):
            fix_file(os.path.join(root, f))
print('Imports updated')
