import 'package:flutter/material.dart';
import '../models/study_material.dart';
import 'package:fe/theme/nightTheme.dart';

class MaterialCard extends StatelessWidget {
  final StudyMaterial material;
  final VoidCallback onTap;

  const MaterialCard({
    super.key,
    required this.material,
    required this.onTap,
  });

  IconData get icon {
    switch (material.type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;

      case 'image':
        return Icons.image_rounded;

      case 'document':
        return Icons.description_rounded;

      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),

      child: Container(
        padding: const EdgeInsets.all(15),

        decoration: BoxDecoration(
          color: AppColors.darkElegance,
          borderRadius: BorderRadius.circular(14),
        ),

        child: Row(
          children: [

            Container(
              width: 45,
              height: 45,

              decoration: BoxDecoration(
                color: AppColors.brandNightBlue,
                borderRadius: BorderRadius.circular(12),
              ),

              child: Icon(
                icon,
                color: AppColors.skyBlue,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(
                    material.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '${material.type} • ${material.size}',

                    style: TextStyle(
                      color: AppColors.pureWhite.withOpacity(0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white38,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }
}