import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'reflexa_backend.settings')
django.setup()

from django.contrib.auth.models import User
from rehab.models import Profile, TherapistRequest, SessionResult, Exercise

def main():
    print("Seeding Dashboard Data...")
    
    # Ensure therapist exists (admin)
    therapist, created = User.objects.get_or_create(username='admin')
    if created:
        therapist.set_password('admin123')
        therapist.is_staff = True
        therapist.is_superuser = True
        therapist.save()
    
    # Update therapist profile
    profile, _ = Profile.objects.get_or_create(user=therapist)
    profile.role = 'THERAPIST'
    profile.save()
    
    # Ensure patient exists (patient1)
    patient, created = User.objects.get_or_create(username='patient1')
    if created:
        patient.set_password('patient123')
        patient.save()
    
    p_profile, _ = Profile.objects.get_or_create(user=patient)
    p_profile.role = 'PATIENT'
    p_profile.age = 28
    p_profile.medical_condition = 'Right ACL Recovery'
    p_profile.therapist = therapist
    p_profile.save()
    
    # Create some dummy results for patient1
    exercise = Exercise.objects.first()
    if exercise:
        SessionResult.objects.get_or_create(
            patient=patient,
            exercise=exercise,
            accuracy=85.0,
            time_taken=120,
            score=850
        )
        SessionResult.objects.get_or_create(
            patient=patient,
            exercise=exercise,
            accuracy=92.5,
            time_taken=115,
            score=925
        )

    # Create a pending request
    p2, _ = User.objects.get_or_create(username='patient2')
    p2.set_password('patient123')
    p2.save()
    Profile.objects.get_or_create(user=p2, role='PATIENT')
    
    TherapistRequest.objects.get_or_create(
        patient=p2,
        therapist=therapist,
        name='Sarah Johnson',
        defaults={
            'age': 35,
            'phone': '555-0199',
            'email': 'sarah.j@example.com',
            'injury_type': 'Shoulder Rotator Cuff Tear',
            'status': 'PENDING'
        }
    )

    print("Seeding complete.")

if __name__ == '__main__':
    main()
