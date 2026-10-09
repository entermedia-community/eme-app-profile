import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:eme_world/screens/server/tabs/server_chat_tab.dart';
import 'package:eme_world/widgets/chat/product_detail_modal.dart';
import 'package:eme_world/widgets/chat/product_message_card.dart';
import 'package:eme_world/widgets/chat/send_product_sheet.dart';
import 'test_helpers.dart';

class _MockProductApiService extends MockApiService {
  final List<ChatMessage> mockMessages;
  _MockProductApiService(this.mockMessages);

  @override
  Future<List<ChatMessage>> fetchServerChatMessages(
    String channelId, {
    String? serverId,
    String? baseUrl,
  }) async {
    return mockMessages;
  }
}

void main() {
  group('ProductMessageModel Tests', () {
    test('Catalog items correctly populate models and helper getters', () {
      final catalog = ProductMessageModel.sampleCatalog;
      expect(catalog.length, greaterThanOrEqualTo(6));

      // 1. E-Commerce
      final ecom = catalog.firstWhere((p) => p.type == ProductType.ecommerce);
      expect(ecom.type, ProductType.ecommerce);
      expect(ecom.primaryActionLabel, 'Buy Now');
      expect(ecom.typeLabel, 'Product');
      expect(ecom.formattedPrice, contains('\$'));

      // 2. Rideshare
      final ride = catalog.firstWhere((p) => p.type == ProductType.rideshare);
      expect(ride.type, ProductType.rideshare);
      expect(ride.primaryActionLabel, 'Book Seat');
      expect(ride.typeLabel, 'Rideshare');
      expect(ride.origin, isNotNull);
      expect(ride.destination, isNotNull);

      // 3. Rental (House)
      final house = catalog.firstWhere(
        (p) =>
            p.type == ProductType.rental &&
            p.rentalCategory == RentalCategory.house,
      );
      expect(house.primaryActionLabel, 'Book Stay');
      expect(house.typeLabel, 'House Rental');

      // 4. Rental (Gear)
      final gear = catalog.firstWhere(
        (p) =>
            p.type == ProductType.rental &&
            p.rentalCategory == RentalCategory.gear,
      );
      expect(gear.primaryActionLabel, 'Rent Now');
      expect(gear.typeLabel, 'Gear Rental');
    });
  });

  group('Product UI Widget Tests', () {
    testWidgets(
      'ProductMessageCard renders product details and opens detail modal on tap',
      (tester) async {
        final product = ProductMessageModel.sampleCatalog[0];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ProductMessageCard(product: product)),
          ),
        );

        expect(find.text(product.title), findsOneWidget);
        expect(find.text(product.formattedPrice), findsOneWidget);
        expect(
          find.text('BUY NOW'),
          findsNothing,
        ); // primaryActionLabel is 'Buy Now'
        expect(find.text('Buy Now'), findsOneWidget);

        // Tap card to open modal
        await tester.tap(find.byType(ProductMessageCard));
        await tester.pumpAndSettle();

        expect(find.byType(ProductDetailModal), findsOneWidget);
        expect(find.text('Overview'), findsOneWidget);
        expect(find.text('Inventory & Delivery'), findsOneWidget);
      },
    );

    testWidgets(
      'ServerChatTab renders server-specific product messages for Marketplace server',
      (tester) async {
        const marketplaceServer = ServerModel(
          id: 'srv_010',
          name: 'Artisan Goods & Organic Market',
          description:
              'Direct-to-consumer marketplace for single-origin shade coffee.',
          category: ServerCategoryModel(
            id: 'marketplace',
            name: 'Marketplace & Goods',
          ),
          primaryColor: Color(0xFFD97706),
        );

        final catalog = ProductMessageModel.sampleCatalog;
        final coffee = catalog.firstWhere(
          (p) => p.type == ProductType.ecommerce,
        );

        final mockApi = _MockProductApiService([
          ChatMessage(
            messageId: 'msg_market_1',
            channel: 'srv_010',
            userId: 'artisan_lead',
            message: 'Shared a product: ${coffee.title}',
            messageType: 'product',
            product: coffee,
            createdAt: DateTime.now(),
          ),
        ]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [apiServiceProvider.overrideWithValue(mockApi)],
            child: const MaterialApp(
              home: Scaffold(body: ServerChatTab(server: marketplaceServer)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify marketplace product cards are rendered
        expect(
          find.text(
            'Single-Origin Atitlan Gesha Coffee (500g)',
            skipOffstage: false,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ServerChatTab renders rideshare product messages for Mobility server',
      (tester) async {
        const mobilityServer = ServerModel(
          id: 'srv_009',
          name: 'EcoTransit Mobility & Rides',
          description: 'Zero-emission rideshare and shuttle service.',
          category: ServerCategoryModel(
            id: 'Mobility & Rides',
            name: 'Mobility & Rides',
          ),
          primaryColor: Color(0xFF0284C7),
        );

        final catalog = ProductMessageModel.sampleCatalog;
        final ride = catalog.firstWhere((p) => p.type == ProductType.rideshare);

        final mockApi = _MockProductApiService([
          ChatMessage(
            messageId: 'msg_ride_1',
            channel: 'srv_009',
            userId: 'driver_alex',
            message: 'Shared a rideshare: ${ride.title}',
            messageType: 'product',
            product: ride,
            createdAt: DateTime.now(),
          ),
        ]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [apiServiceProvider.overrideWithValue(mockApi)],
            child: const MaterialApp(
              home: Scaffold(body: ServerChatTab(server: mobilityServer)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify rideshare product card is rendered
        expect(
          find.text(
            'Panajachel ➔ Guatemala City Express EV Shuttle',
            skipOffstage: false,
          ),
          findsOneWidget,
        );
        expect(find.text('Book Seat', skipOffstage: false), findsOneWidget);
      },
    );

    testWidgets(
      'ServerChatTab renders rental product messages for Rental & Gear server',
      (tester) async {
        const rentalServer = ServerModel(
          id: 'srv_008',
          name: 'Gear Rentals',
          description: 'Equipment, villa rentals, and tool lending.',
          category: ServerCategoryModel(
            id: 'rental_gear',
            name: 'Rental & Gear',
          ),
          primaryColor: Color(0xFF0D9488),
        );

        final catalog = ProductMessageModel.sampleCatalog;
        final house = catalog.firstWhere(
          (p) =>
              p.type == ProductType.rental &&
              p.rentalCategory == RentalCategory.house,
        );

        final mockApi = _MockProductApiService([
          ChatMessage(
            messageId: 'msg_rent_1',
            channel: 'srv_008',
            userId: 'host_maria',
            message: 'Shared a rental: ${house.title}',
            messageType: 'product',
            product: house,
            createdAt: DateTime.now(),
          ),
        ]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [apiServiceProvider.overrideWithValue(mockApi)],
            child: const MaterialApp(
              home: Scaffold(body: ServerChatTab(server: rentalServer)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify rental product cards are rendered
        expect(
          find.text(
            'Lakeview Solar Eco-Villa with Private Dock',
            skipOffstage: false,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'SendProductSheet allows selecting and sending a product to chat',
      (tester) async {
        ProductMessageModel? selectedProduct;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    SendProductSheet.show(
                      context,
                      onProductSelected: (p) => selectedProduct = p,
                    );
                  },
                  child: const Text('Open Picker'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Picker'));
        await tester.pumpAndSettle();

        expect(find.text('Share Product in Chat'), findsOneWidget);
        expect(find.text('Send'), findsWidgets);

        // Tap first 'Send' button
        await tester.tap(find.text('Send').first);
        await tester.pumpAndSettle();

        expect(selectedProduct, isNotNull);
        expect(selectedProduct!.title, contains('Gesha Coffee'));
      },
    );
  });
}
