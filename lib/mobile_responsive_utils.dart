import 'package:flutter/material.dart';

class MobileResponsiveUtils {
  // Screen size breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;

  // Check if current screen is mobile size
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  // Check if current screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  // Check if current screen is desktop size
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  // Get responsive grid columns
  static int getGridColumns(
    BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Get responsive padding
  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    double mobile = 16.0,
    double tablet = 20.0,
    double desktop = 24.0,
  }) {
    if (isMobile(context)) return EdgeInsets.all(mobile);
    if (isTablet(context)) return EdgeInsets.all(tablet);
    return EdgeInsets.all(desktop);
  }

  // Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context, {
    double mobile = 14.0,
    double tablet = 16.0,
    double desktop = 18.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Get responsive button height
  static double getResponsiveButtonHeight(BuildContext context) {
    return isMobile(context) ? 48.0 : 56.0;
  }

  // Get responsive icon size
  static double getResponsiveIconSize(
    BuildContext context, {
    double mobile = 20.0,
    double tablet = 24.0,
    double desktop = 28.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Get responsive spacing
  static double getResponsiveSpacing(
    BuildContext context, {
    double mobile = 8.0,
    double tablet = 12.0,
    double desktop = 16.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Build responsive grid view
  static Widget buildResponsiveGrid({
    required BuildContext context,
    required List<Widget> children,
    int? mobileColumns,
    int? tabletColumns,
    int? desktopColumns,
    double? aspectRatio,
    double? spacing,
  }) {
    final columns = getGridColumns(
      context,
      mobile: mobileColumns ?? 2,
      tablet: tabletColumns ?? 3,
      desktop: desktopColumns ?? 4,
    );

    final gridSpacing = spacing ?? getResponsiveSpacing(context);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      crossAxisSpacing: gridSpacing,
      mainAxisSpacing: gridSpacing,
      childAspectRatio: aspectRatio ?? 1.0,
      children: children,
    );
  }

  // Build responsive container
  static Widget buildResponsiveContainer({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? borderRadius,
  }) {
    return Container(
      padding: padding ?? getResponsivePadding(context),
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  // Build responsive button
  static Widget buildResponsiveButton({
    required BuildContext context,
    required String text,
    required VoidCallback? onPressed,
    Color? color,
    Color? textColor,
    IconData? icon,
    bool isLoading = false,
    bool isOutlined = false,
  }) {
    final buttonHeight = getResponsiveButtonHeight(context);
    final fontSize = getResponsiveFontSize(
      context,
      mobile: 14,
      tablet: 16,
      desktop: 16,
    );

    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: color ?? Theme.of(context).primaryColor,
            side: BorderSide(color: color ?? Theme.of(context).primaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: Size(double.infinity, buttonHeight),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: color ?? Theme.of(context).primaryColor,
            foregroundColor: textColor ?? Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: Size(double.infinity, buttonHeight),
            elevation: 2,
          );

    final buttonChild = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                textColor ?? Colors.white,
              ),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: getResponsiveIconSize(
                    context,
                    mobile: 18,
                    tablet: 20,
                    desktop: 20,
                  ),
                ),
                SizedBox(width: getResponsiveSpacing(context)),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    return isOutlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: buttonStyle,
            child: buttonChild,
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: buttonStyle,
            child: buttonChild,
          );
  }

  // Build responsive text field
  static Widget buildResponsiveTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    String? hintText,
    IconData? prefixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines,
    bool enabled = true,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: getResponsiveSpacing(context)),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines ?? 1,
        enabled: enabled,
        style: TextStyle(
          fontSize: getResponsiveFontSize(
            context,
            mobile: 14,
            tablet: 16,
            desktop: 16,
          ),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  size: getResponsiveIconSize(
                    context,
                    mobile: 20,
                    tablet: 22,
                    desktop: 24,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: getResponsivePadding(context).horizontal / 2,
            vertical: getResponsivePadding(context).vertical / 2,
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade100,
        ),
      ),
    );
  }

  // Build responsive card
  static Widget buildResponsiveCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? color,
    double? elevation,
  }) {
    return Card(
      margin: margin ?? EdgeInsets.all(getResponsiveSpacing(context)),
      elevation: elevation ?? 2,
      color: color ?? Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: padding ?? getResponsivePadding(context),
        child: child,
      ),
    );
  }

  // Build responsive modal
  static void showResponsiveModal({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool useRootNavigator = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible,
      useRootNavigator: useRootNavigator,
      builder: (modalContext) => Container(
        height:
            MediaQuery.of(modalContext).size.height *
            (isMobile(modalContext) ? 0.9 : 0.8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Modal handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title if provided
            if (title != null) ...[
              Padding(
                padding: getResponsivePadding(modalContext),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: getResponsiveFontSize(
                      modalContext,
                      mobile: 18,
                      tablet: 20,
                      desktop: 22,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
            ],

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: getResponsivePadding(modalContext),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
