import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'reflexa_backend.settings')
django.setup()

from django.contrib.auth.models import User
from rehab.models import Exercise, ExerciseAssignment

def seed_assignments():
    # Get the patient user (ID 2)
    try:
        patient = User.objects.get(username='patient1')
        print(f"Found patient: {patient.username} (ID: {patient.id})")
    except User.DoesNotExist:
        print("Patient 'patient1' not found. Run seed_data.py first.")
        return

    # Get some exercises
    exercises = Exercise.objects.all()
    if not exercises.exists():
        print("No exercises found. Run seed_data.py first.")
        return

    # Clear existing assignments for this patient
    ExerciseAssignment.objects.filter(patient=patient).delete()
    print("Cleared existing assignments.")

    # Create new assignments
    for ex in exercises:
        ExerciseAssignment.objects.create(
            patient=patient,
            exercise=ex,
            reps=10,
            difficulty='Medium',
            status='ASSIGNED'
        )
        print(f"Assigned '{ex.name}' to {patient.username}")

    print("Assignments seeded successfully.")

if __name__ == "__main__":
    seed_assignments()
