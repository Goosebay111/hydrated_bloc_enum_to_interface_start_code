import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

enum Item {
  magical(7),
  sharp(5);

  const Item(this.damage);
  final int damage;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HydratedBloc.storage = await initializeHydratedStorage();

  runApp(const DIProviderTree());
}

Future<HydratedStorage> initializeHydratedStorage() async {
  return HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getTemporaryDirectory(),
  );
}

class DIProviderTree extends StatelessWidget {
  const DIProviderTree({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SubjectBloc>(
          create: (context) => SubjectBloc(),
        ),
      ],
      child: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            DisplayCircleAvatar(),
            ChipsHolder(),
          ],
        ),
      )),
    );
  }
}

class ChipsHolder extends StatelessWidget {
  const ChipsHolder({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
        children: Item.values.map((Item enumValue) {
      return SubjectChip(item: enumValue);
    }).toList());
  }
}

class SubjectChip extends StatelessWidget {
  const SubjectChip({super.key, required this.item});
  final Item item;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubjectBloc, SubjectState>(
      builder: (context, state) {
        return ActionChip(
          backgroundColor:
              state.selectedSubjects.contains(item) ? Colors.green : Colors.red,
          label: Text(item.name),
          onPressed: () {
            context.read<SubjectBloc>().add(ModifySelectionSubjectEvent(item));
          },
        );
      },
    );
  }
}

class DisplayCircleAvatar extends StatelessWidget {
  const DisplayCircleAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 100,
      backgroundColor: Colors.blue,
      child: Text(context
          .watch<SubjectBloc>()
          .state
          .selectedSubjects
          .fold(0, (sum, item) => sum + item.damage)
          .toString()),
    );
  }
}

class SubjectBloc extends HydratedBloc<SubjectEvent, SubjectState> {
  SubjectBloc() : super(SubjectState.initial()) {
    on<ModifySelectionSubjectEvent>((event, emit) {
      if (state.selectedSubjects.contains(event.item)) {
        return emit(SubjectState(
            selectedSubjects: state.selectedSubjects..remove(event.item)));
      } else {
        return emit(SubjectState(
            selectedSubjects: state.selectedSubjects..add(event.item)));
      }
    });
  }

  @override
  SubjectState? fromJson(Map<String, dynamic> json) {
    return SubjectState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(SubjectState state) {
    return state.toJson();
  }
}

class SubjectState {
  SubjectState({required this.selectedSubjects});

  static const String _key = 'subject_state';
  final List<Item> selectedSubjects;

  Map<String, dynamic> toJson() {
    return {_key: selectedSubjects.map((e) => e.name).toList()};
  }

  factory SubjectState.fromJson(Map<String, dynamic> json) {
    return SubjectState(
      selectedSubjects: json[_key]
          .map<Item>(
              (e) => Item.values.firstWhere((element) => element.name == e))
          .toList(),
    );
  }

  factory SubjectState.initial() => SubjectState(selectedSubjects: []);
}

abstract class SubjectEvent {}

class ModifySelectionSubjectEvent extends SubjectEvent {
  ModifySelectionSubjectEvent(this.item);
  final Item item;
}