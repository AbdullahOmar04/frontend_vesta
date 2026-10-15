import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';

/// The prototype's icon gallery, by section. Keys are Phosphor's kebab-case
/// names (as the prototype stores them, minus the `ph-` prefix), so goals and
/// households keep a plain string in Firestore.
const iconGallery = <(String, List<String>)>[
  (
    'Food & drink',
    [
      'shopping-cart',
      'basket',
      'fork-knife',
      'coffee',
      'pizza',
      'hamburger',
      'wine',
      'beer-bottle',
      'cooking-pot',
      'ice-cream',
      'bowl-food',
      'orange',
    ],
  ),
  (
    'Home & bills',
    [
      'house-line',
      'lightning',
      'drop',
      'flame',
      'wifi-high',
      'device-mobile',
      'television-simple',
      'repeat',
      'receipt',
      'wrench',
      'broom',
      'couch',
    ],
  ),
  (
    'Transport & travel',
    [
      'car',
      'gas-pump',
      'bus',
      'taxi',
      'train',
      'bicycle',
      'airplane-tilt',
      'suitcase',
      'map-pin',
      'globe-hemisphere-east',
      'tent',
      'boat',
    ],
  ),
  (
    'Lifestyle',
    [
      'shopping-bag',
      't-shirt',
      'sneaker',
      'popcorn',
      'game-controller',
      'music-notes',
      'book-open',
      'barbell',
      'heartbeat',
      'pill',
      'scissors',
      'sparkle',
    ],
  ),
  (
    'People & other',
    [
      'gift',
      'paw-print',
      'baby',
      'graduation-cap',
      'briefcase',
      'hand-heart',
      'users-three',
      'church',
      'star',
      'tag',
      'piggy-bank',
      'bank',
    ],
  ),
];

const _icons = <String, IconData>{
  'shopping-cart': PhosphorIconsRegular.shoppingCart,
  'basket': PhosphorIconsRegular.basket,
  'fork-knife': PhosphorIconsRegular.forkKnife,
  'coffee': PhosphorIconsRegular.coffee,
  'pizza': PhosphorIconsRegular.pizza,
  'hamburger': PhosphorIconsRegular.hamburger,
  'wine': PhosphorIconsRegular.wine,
  'beer-bottle': PhosphorIconsRegular.beerBottle,
  'cooking-pot': PhosphorIconsRegular.cookingPot,
  'ice-cream': PhosphorIconsRegular.iceCream,
  'bowl-food': PhosphorIconsRegular.bowlFood,
  'orange': PhosphorIconsRegular.orange,
  'house-line': PhosphorIconsRegular.houseLine,
  'lightning': PhosphorIconsRegular.lightning,
  'drop': PhosphorIconsRegular.drop,
  'flame': PhosphorIconsRegular.flame,
  'wifi-high': PhosphorIconsRegular.wifiHigh,
  'device-mobile': PhosphorIconsRegular.deviceMobile,
  'television-simple': PhosphorIconsRegular.televisionSimple,
  'repeat': PhosphorIconsRegular.repeat,
  'receipt': PhosphorIconsRegular.receipt,
  'wrench': PhosphorIconsRegular.wrench,
  'broom': PhosphorIconsRegular.broom,
  'couch': PhosphorIconsRegular.couch,
  'car': PhosphorIconsRegular.car,
  'gas-pump': PhosphorIconsRegular.gasPump,
  'bus': PhosphorIconsRegular.bus,
  'taxi': PhosphorIconsRegular.taxi,
  'train': PhosphorIconsRegular.train,
  'bicycle': PhosphorIconsRegular.bicycle,
  'airplane-tilt': PhosphorIconsRegular.airplaneTilt,
  'suitcase': PhosphorIconsRegular.suitcase,
  'map-pin': PhosphorIconsRegular.mapPin,
  'globe-hemisphere-east': PhosphorIconsRegular.globeHemisphereEast,
  'tent': PhosphorIconsRegular.tent,
  'boat': PhosphorIconsRegular.boat,
  'shopping-bag': PhosphorIconsRegular.shoppingBag,
  't-shirt': PhosphorIconsRegular.tShirt,
  'sneaker': PhosphorIconsRegular.sneaker,
  'popcorn': PhosphorIconsRegular.popcorn,
  'game-controller': PhosphorIconsRegular.gameController,
  'music-notes': PhosphorIconsRegular.musicNotes,
  'book-open': PhosphorIconsRegular.bookOpen,
  'barbell': PhosphorIconsRegular.barbell,
  'heartbeat': PhosphorIconsRegular.heartbeat,
  'pill': PhosphorIconsRegular.pill,
  'scissors': PhosphorIconsRegular.scissors,
  'sparkle': PhosphorIconsRegular.sparkle,
  'gift': PhosphorIconsRegular.gift,
  'paw-print': PhosphorIconsRegular.pawPrint,
  'baby': PhosphorIconsRegular.baby,
  'graduation-cap': PhosphorIconsRegular.graduationCap,
  'briefcase': PhosphorIconsRegular.briefcase,
  'hand-heart': PhosphorIconsRegular.handHeart,
  'users-three': PhosphorIconsRegular.usersThree,
  'church': PhosphorIconsRegular.church,
  'star': PhosphorIconsRegular.star,
  'tag': PhosphorIconsRegular.tag,
  'piggy-bank': PhosphorIconsRegular.piggyBank,
  'bank': PhosphorIconsRegular.bank,
  // Not in the gallery, but used by the prototype's sample data
  'buildings': PhosphorIconsRegular.buildings,
  'lifebuoy': PhosphorIconsRegular.lifebuoy,
  'laptop': PhosphorIconsRegular.laptop,
};

/// The icon for a stored key ('piggy-bank', or the prototype's
/// 'ph-piggy-bank'), or [fallback] when the key is missing or unknown.
IconData iconForKey(
  String? key, {
  IconData fallback = PhosphorIconsRegular.piggyBank,
}) {
  if (key == null) return fallback;
  return _icons[key.startsWith('ph-') ? key.substring(3) : key] ?? fallback;
}

/// The prototype's "Choose an icon" sheet. Returns the chosen key, or null
/// when it was closed.
Future<String?> showIconPicker(BuildContext context, {String? selected}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final v = sheetContext.vesta;
      final accent = Theme.of(sheetContext).colorScheme.primary;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            VestaSpace.gutter,
            0,
            VestaSpace.gutter,
            VestaSpace.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Choose an icon', style: headingStyle(20)),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: Icon(PhosphorIconsRegular.x, color: v.muted),
                  ),
                ],
              ),
              for (final (section, keys) in iconGallery) ...[
                const SizedBox(height: VestaSpace.md),
                Text(section, style: TextStyle(fontSize: 12, color: v.muted)),
                const SizedBox(height: VestaSpace.sm),
                GridView.count(
                  crossAxisCount: 6,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (final key in keys)
                      Material(
                        color: key == selected ? v.tint : v.raised,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: key == selected
                                ? accent
                                : Colors.transparent,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.pop(sheetContext, key),
                          child: Icon(
                            iconForKey(key),
                            size: 22,
                            color: key == selected ? v.tintText : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// A stored icon in a rounded square, with a small pencil badge when it can
/// be changed. Old goals saved an emoji instead, so [emoji] shows when there
/// is no [iconKey].
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    this.iconKey,
    this.emoji,
    this.size = 40,
    this.fallback = PhosphorIconsRegular.piggyBank,
    this.onTap,
  });

  final String? iconKey;
  final String? emoji;
  final double size;
  final IconData fallback;

  /// Shows the pencil badge and makes the tile tappable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final useEmoji = iconKey == null && emoji != null && emoji!.isNotEmpty;
    final tile = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: v.raised,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: useEmoji
          ? Text(emoji!, style: TextStyle(fontSize: size * 0.5))
          : Icon(
              iconForKey(iconKey, fallback: fallback),
              size: size * 0.5,
              color: v.accentInk,
            ),
    );
    if (onTap == null) return tile;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          tile,
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: v.raised,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  width: 2,
                ),
              ),
              child: Icon(
                PhosphorIconsRegular.pencilSimple,
                size: 10,
                color: v.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
