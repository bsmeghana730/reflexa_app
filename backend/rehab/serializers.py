from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Profile, Exercise, ExerciseAssignment, SessionResult

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email']

class ExerciseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Exercise
        fields = '__all__'

class ExerciseAssignmentSerializer(serializers.ModelSerializer):
    exercise_name = serializers.ReadOnlyField(source='exercise.name')
    patient_name = serializers.ReadOnlyField(source='patient.username')
    
    class Meta:
        model = ExerciseAssignment
        fields = '__all__'

class SessionResultSerializer(serializers.ModelSerializer):
    class Meta:
        model = SessionResult
        fields = '__all__'
