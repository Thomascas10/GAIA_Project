import 'package:gaia/model/general_quest.dart';
import 'package:gaia/services/general_quest_service.dart';
import 'package:gaia/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gaia/provider/user_provider.dart';

class AllQuestsPage extends StatefulWidget {
  const AllQuestsPage({super.key});

  @override
  State<AllQuestsPage> createState() => _AllQuestsPageState();
}

class _AllQuestsPageState extends State<AllQuestsPage> {
  final GeneralQuestService _questService = GeneralQuestService();
  final UserService _userService = UserService();

  late Future<void> _combinedFuture;
  List<GeneralQuest> _quests = [];
  List<Map<String, dynamic>> _questProgressData = [];

  @override
  void initState() {
    super.initState();

    final user = Provider.of<UserProvider>(context, listen: false).user;
    final uid = user?.id ?? "default_uid";

    _combinedFuture = _questService.fetchGeneralQuests().then((quests) async {
      final progress = await _userService.getQuests(uid);
      final progressData = getProgressionAndGoal(quests, progress);

      setState(() {
        _quests = quests;
        _questProgressData = progressData;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Toutes les Quêtes"),
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quêtes Générales",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Chargement des quêtes
            Expanded(
              child: FutureBuilder<void>(
                future: _combinedFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    itemCount: _quests.length,
                    itemBuilder: (context, index) {
                      final quest = _quests[index];

                      // Cherche la progression correspondante
                      final progressData = _questProgressData.firstWhere(
                        (element) => element['id'] == quest.id,
                        orElse: () => {'progression': 0, 'goal': quest.goal[0]},
                      );

                      final int progression = progressData['progression'];
                      final int goal = progressData['goal'];

                      // Détermine le niveau d'étoiles
                      int level = 0;
                      if (progression >= quest.goal[2]) {
                        level = 3;
                      } else if (progression >= quest.goal[1]) {
                        level = 2;
                      } else if (progression >= quest.goal[0]) {
                        level = 1;
                      }

                      List<Widget> stars = List.generate(
                        3,
                        (i) => Icon(
                          i < level ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                      );

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Partie gauche : infos + étoiles
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      quest.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(quest.description),
                                    const SizedBox(height: 6),
                                    Row(children: stars),
                                  ],
                                ),
                              ),

                              // Partie droite : progression actuelle
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "$progression / $goal",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Progression",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔁 Nouvelle fonction utilisée uniquement
List<Map<String, dynamic>> getProgressionAndGoal(
  List<GeneralQuest> questList,
  List<Map<String, dynamic>> progressList,
) {
  List<Map<String, dynamic>> result = [];

  for (var progress in progressList) {
    final String questId = progress['id'].toString();
    final int currentProgress = progress['progression'];

    final matchingQuest = questList.firstWhere(
      (quest) => quest.id == questId,
      orElse: () => GeneralQuest(
        id: questId,
        title: '',
        description: '',
        movement: '',
        goal: [0, 0, 0],
      ),
    );

    int goalToReach = matchingQuest.goal.firstWhere(
      (goal) => currentProgress < goal,
      orElse: () => matchingQuest.goal.last,
    );

    result.add({
      'id': questId,
      'progression': currentProgress,
      'goal': goalToReach,
    });
  }

  return result;
}
