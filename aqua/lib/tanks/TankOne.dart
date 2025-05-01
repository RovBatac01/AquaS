import 'package:flutter/material.dart';
import 'package:aqua/components/Details.dart'; // Import the DetailsScreen

class HomeWaterTankCard extends StatelessWidget {
  const HomeWaterTankCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
        margin: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 12,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sample Tank',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded( // Use Expanded to take up remaining vertical space
                child: Container(), // Use an empty container to push the buttons to the bottom
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the bottom right
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DetailsScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(60, 35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), // Add some horizontal space between the buttons
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.blueAccent,
                      size: 25,
                    ),
                    onPressed: () {
                      // Add edit function here
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

