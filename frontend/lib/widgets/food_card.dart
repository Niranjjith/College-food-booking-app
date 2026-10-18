import 'package:flutter/material.dart';
import '../models/food.dart';
import '../theme/app_colors.dart';

class FoodCard extends StatelessWidget {
  final Food food;
  final VoidCallback onAdd;

  const FoodCard({super.key, required this.food, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onAdd,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _FoodThumb(food: food, size: 78),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        food.category.isEmpty ? "Campus kitchen" : food.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _ChipLabel(
                            text: "₹${food.price.toStringAsFixed(0)}",
                            color: AppColors.primary,
                          ),
                          if (food.nutrition?['calories'] != null)
                            _ChipLabel(
                              text: "${food.nutrition!['calories']} kcal",
                              color: AppColors.accent,
                              icon: Icons.local_fire_department,
                            ),
                          if (food.isHealthy)
                            const _ChipLabel(
                              text: "Healthy",
                              color: AppColors.primary,
                              icon: Icons.eco,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _AddButton(onAdd: onAdd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FeaturedFoodCard extends StatelessWidget {
  final Food food;
  final VoidCallback onAdd;

  const FeaturedFoodCard({super.key, required this.food, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 108,
              width: double.infinity,
              child: food.imageUrl.isNotEmpty
                  ? Image.network(food.imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      child: const Icon(Icons.restaurant, color: AppColors.primary, size: 40),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      "₹${food.price.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    _AddButton(onAdd: onAdd, compact: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodThumb extends StatelessWidget {
  const _FoodThumb({required this.food, required this.size});

  final Food food;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.primary.withValues(alpha: 0.1),
        image: food.imageUrl.isNotEmpty
            ? DecorationImage(image: NetworkImage(food.imageUrl), fit: BoxFit.cover)
            : null,
      ),
      child: food.imageUrl.isEmpty
          ? const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 34)
          : null,
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onAdd, this.compact = false});

  final VoidCallback onAdd;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 44.0;
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onAdd,
          child: Icon(Icons.add, color: Colors.white, size: compact ? 18 : 22),
        ),
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.text, required this.color, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
