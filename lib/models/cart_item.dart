import 'menu_item.dart';

class CartItem {
  final MenuItem menu;
  final int quantity;

  const CartItem({
    required this.menu,
    required this.quantity,
  });

  int get subtotal => menu.price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      menu: menu,
      quantity: quantity ?? this.quantity,
    );
  }
}
