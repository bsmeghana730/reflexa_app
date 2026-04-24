import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'reflexa_backend.settings')
django.setup()

from django.contrib.auth.models import User
from rehab.models import Profile

print("List of Users:")
for user in User.objects.all():
    profile = Profile.objects.filter(user=user).first()
    role = profile.role if profile else "No Profile"
    print(f"ID: {user.id}, Username: {user.username}, Role: {role}")
