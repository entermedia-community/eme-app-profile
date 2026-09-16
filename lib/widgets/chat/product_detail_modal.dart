import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product_message_model.dart';
import '../../theme/app_colors.dart';

class ProductDetailModal extends StatefulWidget {
  final ProductMessageModel product;
  final VoidCallback? onCompletedAction;

  const ProductDetailModal({
    super.key,
    required this.product,
    this.onCompletedAction,
  });

  static Future<void> show(
    BuildContext context,
    ProductMessageModel product, {
    VoidCallback? onCompletedAction,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailModal(
        product: product,
        onCompletedAction: onCompletedAction,
      ),
    );
  }

  @override
  State<ProductDetailModal> createState() => _ProductDetailModalState();
}

class _ProductDetailModalState extends State<ProductDetailModal> {
  int _quantityOrUnits = 1;
  bool _isProcessing = false;

  Color _getTypeColor() {
    switch (widget.product.type) {
      case ProductType.ecommerce:
        return const Color(0xFFD97706); // Amber
      case ProductType.rideshare:
        return const Color(0xFF0284C7); // Sky Blue
      case ProductType.rental:
        return const Color(0xFF0D9488); // Teal
    }
  }

  IconData _getTypeIcon() {
    if (widget.product.iconData != null) return widget.product.iconData!;
    switch (widget.product.type) {
      case ProductType.ecommerce:
        return Icons.shopping_bag_outlined;
      case ProductType.rideshare:
        return Icons.electric_car_rounded;
      case ProductType.rental:
        return widget.product.rentalCategory == RentalCategory.house
            ? Icons.villa_outlined
            : Icons.key_rounded;
    }
  }

  void _handleAction() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    Navigator.of(context).pop();

    widget.onCompletedAction?.call();

    final totalPrice = widget.product.price * _quantityOrUnits;
    final formattedTotal = totalPrice % 1 == 0
        ? totalPrice.toInt().toString()
        : totalPrice.toStringAsFixed(2);

    String message;
    switch (widget.product.type) {
      case ProductType.ecommerce:
        message = 'Ordered $_quantityOrUnits x ${widget.product.title} for ${widget.product.currency}$formattedTotal! Escrow initiated.';
        break;
      case ProductType.rideshare:
        message = 'Confirmed $_quantityOrUnits seat(s) on ${widget.product.title}! Driver notified.';
        break;
      case ProductType.rental:
        message = 'Rental booking secured for $_quantityOrUnits unit(s)! Lock/Host credentials sent.';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final bgHeaderColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final typeColor = _getTypeColor();

    final maxUnits = widget.product.type == ProductType.rideshare
        ? (widget.product.availableSeats ?? 4)
        : (widget.product.stockQuantity ?? 10);

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Indicator Bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Scrollable Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  children: [
                    // Header Card with Icon & Type
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bgHeaderColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: typeColor.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(_getTypeIcon(), size: 32, color: typeColor),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: typeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        widget.product.typeLabel.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: typeColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade600),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${widget.product.rating}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      ' (${widget.product.reviewCount})',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.product.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                    color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.product.formattedPrice,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: typeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'Overview',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.product.description,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Specific Product Sections
                    if (widget.product.type == ProductType.rideshare) ...[
                      _buildRideshareSection(isDark, borderColor, typeColor),
                    ] else if (widget.product.type == ProductType.rental) ...[
                      _buildRentalSection(isDark, borderColor, typeColor),
                    ] else ...[
                      _buildEcommerceSection(isDark, borderColor, typeColor),
                    ],

                    const SizedBox(height: 16),

                    // Tags
                    if (widget.product.tags.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: widget.product.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: Text(
                              '#$tag',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Provider / Host Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: typeColor.withValues(alpha: 0.2),
                            child: Icon(Icons.verified_user_rounded, size: 18, color: typeColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product.sellerOrHostName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  widget.product.sellerOrHostRole,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: typeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.product.location != null) ...[
                            Icon(Icons.location_on_outlined, size: 14, color: isDark ? AppColors.textDarkMuted : AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              widget.product.location!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Escrow / Protection Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF059669).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF059669)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Secured by EME Smart Contract Escrow. Instant refund if terms are not met.',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Bottom Action Bar with Counter & Purchase Button
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).padding.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(top: BorderSide(color: borderColor)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Quantity / Seat / Unit Stepper
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_rounded, size: 18),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                            onPressed: _quantityOrUnits > 1
                                ? () => setState(() => _quantityOrUnits--)
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$_quantityOrUnits',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                            onPressed: _quantityOrUnits < maxUnits
                                ? () => setState(() => _quantityOrUnits++)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Action Button
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: typeColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isProcessing ? null : _handleAction,
                        child: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${widget.product.primaryActionLabel} • ${widget.product.currency}${((widget.product.price * _quantityOrUnits) % 1 == 0 ? (widget.product.price * _quantityOrUnits).toInt().toString() : (widget.product.price * _quantityOrUnits).toStringAsFixed(2))}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_rounded, size: 16),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRideshareSection(bool isDark, Color borderColor, Color typeColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, size: 18, color: typeColor),
              const SizedBox(width: 8),
              Text(
                'Route & Schedule',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Route Steps
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.trip_origin_rounded, size: 14, color: Color(0xFF059669)),
                  Container(width: 2, height: 22, color: borderColor),
                  const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFDC2626)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.origin ?? 'Origin point',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.product.destination ?? 'Destination point',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time_filled_rounded, size: 14, color: isDark ? AppColors.textDarkMuted : AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    widget.product.departureTime ?? 'Departing soon',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${widget.product.availableSeats ?? 1} seats left',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                  ),
                ),
              ),
            ],
          ),
          if (widget.product.vehicleInfo != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.directions_car_rounded, size: 14, color: isDark ? AppColors.textDarkMuted : AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.product.vehicleInfo!,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRentalSection(bool isDark, Color borderColor, Color typeColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_outlined, size: 18, color: typeColor),
              const SizedBox(width: 8),
              Text(
                'Specifications & Amenities',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.product.amenitiesOrSpecs.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.product.amenitiesOrSpecs.map((spec) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF059669)),
                    const SizedBox(width: 6),
                    Text(
                      spec,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
          if (widget.product.depositInfo != null) ...[
            Divider(height: 1, color: borderColor),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.lock_clock_rounded, size: 14, color: isDark ? AppColors.textDarkMuted : AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Deposit: ${widget.product.depositInfo}',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEcommerceSection(bool isDark, Color borderColor, Color typeColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 18, color: typeColor),
              const SizedBox(width: 8),
              Text(
                'Inventory & Delivery',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.product.inStock
                      ? '${widget.product.stockQuantity ?? 10} In Stock'
                      : 'Out of Stock',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          if (widget.product.shippingOrPickupInfo != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.local_shipping_outlined, size: 14, color: isDark ? AppColors.textDarkMuted : AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.product.shippingOrPickupInfo!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
