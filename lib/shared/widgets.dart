import 'package:flutter/material.dart';
import 'package:book_hive/shared/const.dart';
import 'package:book_hive/shared/styles.dart';

class Loading extends StatelessWidget {
  const Loading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: primaryColor));
  }
}

class UnderConstruction extends StatelessWidget {
  final double height;

  const UnderConstruction({super.key, this.height = double.infinity});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
        color: height > 10000 ? Colors.white : Colors.grey[200],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 40),
            Text("Under Construction", style: styleH2),
          ],
        ),
      ),
    );
  }
}

class DashboardTitle extends StatelessWidget {
  final String title;
  final Function()? onTapSeeMore;

  const DashboardTitle({super.key, required this.title, this.onTapSeeMore});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: styleH5),
        if (onTapSeeMore != null)
          InkWell(
            onTap: onTapSeeMore,
            child: Text(
              "See All",
              style: styleH6.copyWith(decoration: TextDecoration.underline),
            ),
          ),
      ],
    );
  }
}

class NavBarItem extends StatelessWidget {
  final String title;
  final IconData iconData;
  final bool isSelected;

  const NavBarItem({
    super.key,
    required this.title,
    required this.iconData,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: Colors.amber,
      margin: (isSelected)
          ? const EdgeInsets.all(0)
          : const EdgeInsets.only(top: 10),
      height: (isSelected) ? 50 : 60,
      width: (isSelected) ? 50 : 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(iconData, color: Colors.white, size: (isSelected) ? 30 : 25),
          if (isSelected == false)
            Text(title, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class DrawerNavigationTile extends StatelessWidget {
  final Function() onTap;
  final String title;
  final IconData iconData;

  const DrawerNavigationTile({
    super.key,
    required this.onTap,
    required this.title,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: whiteBodyGreyBordered.copyWith(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        title: Text(title),
        leading: Icon(iconData, color: primaryColor),
        onTap: onTap,
      ),
    );
  }
}

class OrangeCircleIconButton extends StatelessWidget {
  final Function()? onTap;
  final IconData iconData;

  const OrangeCircleIconButton({super.key, this.onTap, required this.iconData});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: primaryColor,
        shape: BoxShape.circle,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(1000.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(iconData, size: 25.0, color: Colors.white),
        ),
      ),
    );
  }
}

class DropdownCustom extends StatefulWidget {
  final String? hintText;
  final String? label;
  final List<String> listOfItems;
  final String? value;
  final Function(dynamic)? onChanged;
  final bool enabled;
  final Function()? onLongPress;

  const DropdownCustom({
    Key? key,
    this.hintText,
    required this.listOfItems,
    required this.value,
    this.label,
    this.onChanged,
    this.enabled = true,
    this.onLongPress,
  }) : super(key: key);

  @override
  State<DropdownCustom> createState() => _DropdownCustomState();
}

class _DropdownCustomState extends State<DropdownCustom> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: (widget.enabled)
          ? () {
              widget.onLongPress!();
            }
          : null,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: widget.label,
          fillColor: Colors.white,
        ),
        items: widget.listOfItems.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: dropdownItemTextStyle),
          );
        }).toList(),
        hint: Text(
          widget.hintText ?? 'Select an Option',
          style: dropdownHintStyle,
        ),
        value: widget.value,
        onChanged: (widget.enabled)
            ? (selection) {
                widget.onChanged!(selection);
              }
            : null,
      ),
    );
  }
}
