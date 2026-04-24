from django.contrib import admin
from .models import Profile, Exercise, ExerciseAssignment, SessionResult, TherapistRequest

# Register your models here.

admin.site.register(Profile)
admin.site.register(Exercise)
admin.site.register(ExerciseAssignment)
admin.site.register(SessionResult)
admin.site.register(TherapistRequest)
