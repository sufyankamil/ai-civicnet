import 'dart:math' show cos, sin, sqrt, asin;
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart'; // For compute
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../services/cache_service.dart';
import '../../../../services/logger_service.dart';
import '../../../../services/supabase_service.dart'; // Temporarily using SupabaseService to get user profile for distance calc until profile feature is ready
import '../datasources/request_remote_data_source.dart';
import '../models/help_request_model.dart';
import '../../domain/entities/help_request_entity.dart';
import '../../domain/repositories/request_repository.dart';
import '../../domain/entities/request_enums.dart';

// Top-level function for compute
List<HelpRequestModel> parseHelpRequestsList(List<dynamic> data) {
  return data.map((json) => HelpRequestModel.fromJson(json)).toList();
}

class RequestRepositoryImpl implements RequestRepository {
  final RequestRemoteDataSource remoteDataSource;

  RequestRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<HelpRequestEntity>>> getHelpRequests() async {
    try {
      final remoteData = await remoteDataSource.getRawHelpRequests();
      await CacheService().put('help_requests', remoteData);
      
      List<HelpRequestEntity> requests = await compute(parseHelpRequestsList, remoteData);
      requests = await _calculateDistances(requests);
      return Right(requests);
    } on ServerException catch (e) {
      try {
        final cachedData = await CacheService().get('help_requests');
        if (cachedData != null) {
          List<HelpRequestEntity> requests = await compute(parseHelpRequestsList, cachedData as List<dynamic>);
          requests = await _calculateDistances(requests);
          return Right(requests);
        }
      } catch (_) {}
      logger.e('Server exception in getHelpRequests: ${e.message}');
      return const Left(ServerFailure('Failed to load help requests.'));
    } catch (e) {
      logger.e('Error in getHelpRequests: $e');
      return const Left(ServerFailure('An unexpected error occurred while loading requests.'));
    }
  }

  @override
  Future<Either<Failure, List<HelpRequestEntity>>> getMyHelpRequests() async {
    try {
      final user = await SupabaseService().getCurrentUserProfile();
      if (user == null) return const Left(ServerFailure('User not logged in'));
      
      final remoteData = await remoteDataSource.getMyRawHelpRequests(user.id);
      List<HelpRequestEntity> requests = await compute(parseHelpRequestsList, remoteData);
      return Right(requests);
    } on ServerException catch (e) {
      logger.e('Server exception in getMyHelpRequests: ${e.message}');
      return const Left(ServerFailure('Failed to load your requests.'));
    } catch (e) {
      logger.e('Error in getMyHelpRequests: $e');
      return const Left(ServerFailure('An unexpected error occurred while loading your requests.'));
    }
  }

  @override
  Future<Either<Failure, HelpRequestEntity>> getHelpRequest(String id) async {
    try {
      final remoteData = await remoteDataSource.getRawHelpRequest(id);
      await CacheService().put('help_request_$id', remoteData);
      
      return Right(HelpRequestModel.fromJson(remoteData));
    } on ServerException catch (e) {
      try {
        final cachedData = await CacheService().get('help_request_$id');
        if (cachedData != null) {
          return Right(HelpRequestModel.fromJson(cachedData));
        }
      } catch (_) {}
      logger.e('Server exception in getHelpRequest: ${e.message}');
      return const Left(ServerFailure('Failed to load the request details.'));
    } catch (e) {
      logger.e('Error in getHelpRequest: $e');
      return const Left(ServerFailure('An unexpected error occurred while loading the request.'));
    }
  }

  @override
  Future<Either<Failure, void>> createHelpRequest(HelpRequestEntity request) async {
    try {
      final model = HelpRequestModel(
        id: request.id,
        requesterId: request.requesterId,
        requesterName: request.requesterName,
        requesterAvatarUrl: request.requesterAvatarUrl,
        title: request.title,
        description: request.description,
        category: request.category,
        urgency: request.urgency,
        postedAt: request.postedAt,
        distance: request.distance,
        aiRelevanceScore: request.aiRelevanceScore,
        locationName: request.locationName,
        lat: request.lat,
        lng: request.lng,
        status: request.status,
      );
      await remoteDataSource.createHelpRequest(model);
      return const Right(null);
    } on ServerException catch (e) {
      logger.e('Server exception in createHelpRequest: ${e.message}');
      return const Left(ServerFailure('Failed to create request. Please try again.'));
    } catch (e) {
      logger.e('Error in createHelpRequest: $e');
      return const Left(ServerFailure('An unexpected error occurred while creating the request.'));
    }
  }

  @override
  Future<Either<Failure, void>> updateHelpRequestStatus(String requestId, RequestStatusEnum status) async {
    try {
      await remoteDataSource.updateHelpRequestStatus(requestId, status);
      return const Right(null);
    } on ServerException catch (e) {
      logger.e('Server exception in updateHelpRequestStatus: ${e.message}');
      return const Left(ServerFailure('Failed to update request status. Please try again.'));
    } catch (e) {
      logger.e('Error in updateHelpRequestStatus: $e');
      return const Left(ServerFailure('An unexpected error occurred while updating the status.'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteHelpRequest(String requestId) async {
    try {
      await remoteDataSource.deleteHelpRequest(requestId);
      
      // Invalidate caches to ensure the UI shows updated data
      await CacheService().delete('help_requests');
      await CacheService().delete('help_request_$requestId');
      
      return const Right(null);
    } on ServerException catch (e) {
      logger.e('Server exception in deleteHelpRequest: ${e.message}');
      return const Left(ServerFailure('Failed to delete request. Please try again.'));
    } catch (e) {
      logger.e('Error in deleteHelpRequest: $e');
      return const Left(ServerFailure('An unexpected error occurred while deleting the request.'));
    }
  }

  @override
  void subscribeToHelpRequests(Function() callback) {
    remoteDataSource.subscribeToHelpRequests(callback);
  }

  @override
  void unsubscribeFromHelpRequests() {
    remoteDataSource.unsubscribeFromHelpRequests();
  }

  Future<List<HelpRequestEntity>> _calculateDistances(List<HelpRequestEntity> requests) async {
    try {
      // Temporarily use SupabaseService for location distance until profile feature refactoring
      final currentUserProfile = await SupabaseService().getCurrentUserProfile();
      
      if (currentUserProfile != null && currentUserProfile.lat != null && currentUserProfile.lng != null && 
          currentUserProfile.lat != 0 && currentUserProfile.lng != 0) {
        
        return requests.map((r) {
          if (r.lat != 0 && r.lng != 0) {
            double distKm = _calculateDistance(r.lat, r.lng, currentUserProfile.lat!, currentUserProfile.lng!);
            return r.copyWith(distance: '${distKm.toStringAsFixed(1)} km');
          }
          return r.copyWith(distance: 'Unknown');
        }).toList();
      } else {
         return requests.map((r) => r.copyWith(distance: 'Unknown')).toList();
      }
    } catch (e) {
      logger.e('Failed to calc distances: $e');
      return requests.map((r) => r.copyWith(distance: 'Unknown')).toList();
    }
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const toRad = 0.017453292519943295; // pi / 180
    final dLat = (lat2 - lat1) * toRad;
    final dLng = (lng2 - lng1) * toRad;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * toRad) * cos(lat2 * toRad) * sin(dLng / 2) * sin(dLng / 2);
    final clampedA = a > 1.0 ? 1.0 : a;
    return 6371.0 * 2 * asin(sqrt(clampedA)); // Earth radius 6371 km
  }
}
