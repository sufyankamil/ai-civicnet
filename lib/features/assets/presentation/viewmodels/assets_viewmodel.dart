import 'dart:io';
import 'package:get/get.dart';
import '../../../../models/models.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/logger_service.dart';
import 'package:uuid/uuid.dart';
import '../../../request/domain/entities/help_request_entity.dart';

class AssetsViewModel extends GetxController {
  final SupabaseService _supabaseService = SupabaseService();
  
  final RxList<CommunityAsset> _myAssets = <CommunityAsset>[].obs;
  List<CommunityAsset> get myAssets => _myAssets;
  
  final RxList<CommunityAsset> _publicAssets = <CommunityAsset>[].obs;
  List<CommunityAsset> get publicAssets => _publicAssets;
  
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  
  final RxnString _errorMessage = RxnString();
  String? get errorMessage => _errorMessage.value;
  
  void clearError() => _errorMessage.value = null;
  
  @override
  void onInit() {
    super.onInit();
    loadMyAssets();
  }
  
  Future<void> loadMyAssets() async {
    _isLoading.value = true;
    try {
      final assets = await _supabaseService.getMyAssets();
      _myAssets.assignAll(assets);
    } catch (e) {
      logger.e('Error loading my assets: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadPublicAssets({AssetCategory? category}) async {
    _isLoading.value = true;
    try {
      final assets = await _supabaseService.getPublicAssets(category: category);
      _publicAssets.assignAll(assets);
    } catch (e) {
      logger.e('Error loading public assets: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> addAsset({
    required String title,
    required String description,
    required AssetCategory category,
    required AssetStatus status,
    File? imageFile,
  }) async {
    _isLoading.value = true;
    try {
      final user = await _supabaseService.getCurrentUserProfile();
      if (user == null) return false;
      
      final asset = CommunityAsset(
        id: const Uuid().v4(),
        ownerId: user.id,
        title: title,
        description: description,
        category: category,
        status: status,
        lat: user.lat,
        lng: user.lng,
        createdAt: DateTime.now(),
      );
      
      _errorMessage.value = null;
      await _supabaseService.createCommunityAsset(asset, imageFile);
      await loadMyAssets();
      return true;
    } catch (e) {
      logger.e('Error adding asset: $e');
      _errorMessage.value = _mapErrorToMessage(e);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  String _mapErrorToMessage(dynamic e) {
    final errorString = e.toString();
    if (errorString.contains('community_assets_category_check')) {
      return 'Invalid category selected. Please try choosing a different one.';
    }
    if (errorString.contains('PostgrestException')) {
      return 'Unable to save to database. Please check your connection and try again.';
    }
    if (errorString.contains('NetworkImage') || errorString.contains('storage')) {
      return 'There was an issue uploading your image. Please try again or skip the image.';
    }
    return 'Something went wrong while listing your asset. Please try again.';
  }

  Future<bool> updateAsset(CommunityAsset asset, {File? imageFile}) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    try {
      await _supabaseService.updateCommunityAsset(asset, imageFile);
      await loadMyAssets();
      return true;
    } catch (e) {
      logger.e('Error updating asset: $e');
      _errorMessage.value = _mapErrorToMessage(e);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> deleteAsset(String assetId) async {
    try {
      await _supabaseService.deleteCommunityAsset(assetId);
      _myAssets.removeWhere((a) => a.id == assetId);
      return true;
    } catch (e) {
      logger.e('Error deleting asset: $e');
      return false;
    }
  }

  Future<List<CommunityAsset>> getMatchForRequest(HelpRequestEntity request) async {
    try {
      return await _supabaseService.matchAssetsForRequest(request);
    } catch (e) {
      logger.e('Error matching assets: $e');
      return [];
    }
  }
}
