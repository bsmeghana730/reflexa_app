import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'reflexa_backend.settings')
django.setup()

from django.contrib.auth.models import User
from rehab.models import Exercise, Profile

# Create superuser if not exists
if not User.objects.filter(username='admin').exists():
    user = User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    Profile.objects.create(user=user, role='THERAPIST')
    print("Superuser 'admin' created.")

# Create a patient user
if not User.objects.filter(username='patient1').exists():
    user = User.objects.create_user('patient1', 'patient1@example.com', 'patient123')
    Profile.objects.create(user=user, role='PATIENT')
    print("Patient 'patient1' created.")

# Clear existing exercises
Exercise.objects.all().delete()
print("Existing exercises cleared.")

# Seed Exercises
exercises = [
    {
        'name': 'Leg Raise',
        'goal': 'Lower limb Exercise',
        'device_count': 1,
        'default_reps': 10
    },
    {
        'name': 'Knee Extension',
        'goal': 'Lower limb Exercise',
        'device_count': 1,
        'default_reps': 10
    },
    {
        'name': 'Wall Support Squat',
        'goal': 'Lower limb Exercise',
        'device_count': 1,
        'default_reps': 10
    },
    {
        'name': 'Stretch Hold',
        'goal': 'Lower limb Exercise',
        'device_count': 1,
        'default_reps': 30
    },
    {
        'name': 'Bridge Lift',
        'goal': 'Core Strength',
        'device_count': 1,
        'default_reps': 15
    },
    {
        'name': 'Plank Hold',
        'goal': 'Core Stability',
        'device_count': 1,
        'default_reps': 60
    },
]

for ex_data in exercises:
    Exercise.objects.create(**ex_data)

print("Exercises seeded successfully.")
