import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../models/drink_model.dart';

class DrinkService {
  final ApiClient _client;

  DrinkService(this._client);

  Future<({List<DrinkModel> defaults, List<DrinkModel> custom})> getDrinks() async {
    final response = await _client.dio.get(ApiConstants.drinks);
    final data = response.data as Map<String, dynamic>;

    final defaults = (data['defaults'] as List<dynamic>? ?? [])
        .map((e) => DrinkModel.fromJson(e as Map<String, dynamic>, isCustom: false))
        .toList();
    final custom = (data['custom'] as List<dynamic>? ?? [])
        .map((e) => DrinkModel.fromJson(e as Map<String, dynamic>, isCustom: true))
        .toList();

    return (defaults: defaults, custom: custom);
  }

  Future<DrinkModel> createCustomDrink({
    required String name,
    String emoji = '🍺',
  }) async {
    final response = await _client.dio.post(ApiConstants.drinks, data: {
      'name': name,
      'emoji': emoji,
    });
    return DrinkModel.fromJson(
      response.data['drink'] as Map<String, dynamic>,
      isCustom: true,
    );
  }

  Future<void> deleteDrink(String drinkId) async {
    await _client.dio.delete(ApiConstants.deleteDrink(drinkId));
  }
}
