import os
import django

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'reflexa_backend.settings')
django.setup()

from rehab.models import Exercise


def create_exercise(name, goal, device_count=1, default_reps=10):
    obj, created = Exercise.objects.get_or_create(
        name=name,
        defaults={
            'goal': goal,
            'device_count': device_count,
            'default_reps': default_reps,
        },
    )
    if created:
        print(f"Created exercise: {name}")
    else:
        print(f"Exercise already exists: {name}")


def main():
    # Straight Leg Raise (Right)
    create_exercise(
        name='Straight Leg Raise (Right)',
        goal='Leg Strength & Range of Motion',
        device_count=1,
        default_reps=10,
    )
    # Straight Leg Raise (Left)
    create_exercise(
        name='Straight Leg Raise (Left)',
        goal='Leg Strength & Range of Motion',
        device_count=1,
        default_reps=10,
    )
    # Straight Leg Raise (Left & Right) – combined alternating version
    create_exercise(
        name='Straight Leg Raise (Left & Right)',
        goal='Leg Strength & Range of Motion',
        device_count=1,
        default_reps=8,
    )
    # Add any other missing exercises here if needed
    
    # Existing placeholder comment (if any) will remain below
    # Right Leg Raise
    create_exercise(
        name='Right Leg Raise',
        goal='Leg Strength & Range of Motion',
        device_count=1,
        default_reps=10,
    )
    # Left Leg Raise
    create_exercise(
        name='Left Leg Raise',
        goal='Leg Strength & Range of Motion',
        device_count=1,
        default_reps=10,
    )
    create_exercise(
        name='Straight Leg Raise (Left)',
        goal='Leg Strength & Range of Motion',
        device_count=1,
        default_reps=10,
    )
    # Add any other missing exercises here if needed


if __name__ == '__main__':
    main()
