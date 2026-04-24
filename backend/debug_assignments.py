import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'reflexa_backend.settings')
django.setup()

from rehab.models import ExerciseAssignment

assignments = ExerciseAssignment.objects.all()
print(f"Total Assignments in DB: {assignments.count()}")
for a in assignments:
    print(f"ID: {a.id}, Patient: {a.patient.username} (ID: {a.patient.id}), Exercise: {a.exercise.name}, Status: {a.status}")
