import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remember_me_please/core/theme/app_theme.dart';
import 'package:remember_me_please/core/widgets/confirmation_dialog.dart';
import 'package:remember_me_please/core/widgets/feature_card.dart';
import 'package:remember_me_please/features/people/pages/add_person_page.dart';
import 'package:remember_me_please/features/people/pages/camera_view_page.dart';
import 'package:remember_me_please/features/people/pages/person_detail_page.dart';
import 'package:remember_me_please/features/people/providers/people_provider.dart';
import 'package:remember_me_please/features/people/widgets/person_card.dart';

class PeoplePage extends StatelessWidget {
  const PeoplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PeoplePageContent();
  }
}

class PeoplePageContent extends StatelessWidget {
  const PeoplePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<PeopleProvider>(
        builder: (context, peopleProvider, child) {
          final people = peopleProvider.people;

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            children: [
              Row(
                children: [
                  Expanded(
                    child: FeatureCard(
                      icon: Icons.person_add,
                      label: 'Add Person',
                      sublabel: 'Add a new face',
                      color: AppColors.primary,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddPersonPage(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FeatureCard(
                      icon: Icons.photo_camera,
                      label: 'Who is this?',
                      sublabel: 'Take a photo',
                      color: AppColors.tertiaryContainer,
                      onColor: AppColors.onTertiaryContainer,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CameraViewPage(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ...people.map(
                (person) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: PersonCard(
                    name: person.name,
                    relationship: person.relationship,
                    description: person.memoryNote1,
                    profilepicturePath: person.profilePicturePath,

                    onTap: () => _navigateToDetail(
                      context,
                      person.name,
                      person.relationship,
                      person.memoryNote1,
                      person.profilePicturePath,
                    ),
                    onEdit: () => _navigateToEditPersonDetail(
                      context,
                      person.id,
                      person.name,
                      person.relationship,
                      person.memoryNote1,
                      person.profilePicturePath,
                    ),
                    onDelete: () {
                      _promptDeletePerson(context, person.name, () {
                        peopleProvider.deletePerson(person.id);
                      });
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToDetail(
    BuildContext context,
    String name,
    String relationship,
    String description,
    String? profilePicturePath,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PersonDetailPage(
          personName: name,
          relationship: relationship,
          description: description,
          profilePicturePath: profilePicturePath,
        ),
      ),
    );
  }

  void _navigateToEditPersonDetail(
    BuildContext context,
    int id,
    String name,
    String relationship,
    String description,
    String? profilePicturePath,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddPersonPage(
          id: id,
          personName: name,
          relationship: relationship,
          description: description,
          profilePicturePath: profilePicturePath,
        ),
      ),
    );
  }

  void _promptDeletePerson(
    BuildContext context,
    String personName,
    VoidCallback onDelete,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          title: Text(
            'Delete Profile?',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 26,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),

          content:
              'Are you sure you want to delete $personName from your people list? This action cannot be undone.',
          confirmText: 'Delete',
          isDestructive: true, // This turns the confirm button red
          onConfirm: () {
            onDelete();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$personName deleted')));
          },
        );
      },
    );
  }
}
