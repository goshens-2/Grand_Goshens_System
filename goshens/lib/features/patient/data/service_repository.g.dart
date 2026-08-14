// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$serviceRepositoryHash() => r'1c1851b56cdd27f6c713260440bb3c3c32ec978d';

/// See also [serviceRepository].
@ProviderFor(serviceRepository)
final serviceRepositoryProvider =
    AutoDisposeProvider<ServiceRepository>.internal(
      serviceRepository,
      name: r'serviceRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$serviceRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ServiceRepositoryRef = AutoDisposeProviderRef<ServiceRepository>;
String _$publishedServicesHash() => r'80c63a6b06ec353fdc7fa587eb43be7767c2ef71';

/// See also [publishedServices].
@ProviderFor(publishedServices)
final publishedServicesProvider =
    AutoDisposeFutureProvider<List<Map<String, dynamic>>>.internal(
      publishedServices,
      name: r'publishedServicesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$publishedServicesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PublishedServicesRef =
    AutoDisposeFutureProviderRef<List<Map<String, dynamic>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
