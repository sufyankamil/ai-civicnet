
/// Initializes all core dependencies for the application.
/// This should be called before `runApp`.
Future<void> initDI() async {
  // Core services
  // Get.lazyPut(() => SomeCoreService());
  
  // Features will have their own init routines called from here
  // e.g. await initAuthDI();
}
