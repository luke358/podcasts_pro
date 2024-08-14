import 'package:get/get.dart';

class MainController extends GetxController {
  int selectedIndex = 0;

  changeIndex(int index) {
   
    selectedIndex = index;
    update();
  }

  // Main pages scroll controller
  // ScrollController homeScrollController = ScrollController();
  // ScrollController searchScrollController = ScrollController();
  // ScrollController listsScrollController = ScrollController();
  // ScrollController profileScrollController = ScrollController();

  // Active API key controller
  int activeApiKey = 0;

  changeActiveApiKey(int index) {
    activeApiKey = index;
    update();
  }
}
