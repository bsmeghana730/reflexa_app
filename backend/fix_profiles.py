from django.contrib.auth.models import User
from rehab.models import Profile

def run():
    print("Fixing user profiles...")
    for user in User.objects.all():
        profile, created = Profile.objects.get_or_create(user=user)
        if created:
            if user.username == 'admin':
                profile.role = 'THERAPIST'
            else:
                profile.role = 'PATIENT'
            profile.save()
            print(f"Created profile for {user.username} as {profile.role}")
        else:
            print(f"Profile exists for {user.username}")

if __name__ == "__main__":
    import os
    import django
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'reflexa_backend.settings')
    django.setup()
    run()
