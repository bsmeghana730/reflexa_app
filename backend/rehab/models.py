from django.db import models
from django.contrib.auth.models import User

class Profile(models.Model):
    ROLE_CHOICES = (
        ('PATIENT', 'Patient'),
        ('THERAPIST', 'Therapist'),
    )
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)
    age = models.IntegerField(null=True, blank=True)
    phone = models.CharField(max_length=15, blank=True, null=True)
    medical_condition = models.TextField(blank=True, null=True)
    therapist = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='patients')

    def __str__(self):
        return f"{self.user.username} - {self.role}"

class Exercise(models.Model):
    name = models.CharField(max_length=100)
    goal = models.TextField()
    device_count = models.IntegerField(default=1)
    default_reps = models.IntegerField(default=10)

    def __str__(self):
        return self.name

class TherapistRequest(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('APPROVED', 'Approved'),
        ('REJECTED', 'Rejected'),
    )
    patient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='requests')
    therapist = models.ForeignKey(User, on_delete=models.CASCADE, related_name='received_requests')
    name = models.CharField(max_length=100)
    age = models.IntegerField()
    phone = models.CharField(max_length=15)
    email = models.EmailField()
    injury_type = models.TextField()
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='PENDING')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Request from {self.name} to {self.therapist.username}"

class ExerciseAssignment(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending Request'),
        ('ASSIGNED', 'Assigned'),
        ('COMPLETED', 'Completed'),
    )
    patient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='assignments')
    therapist = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_tasks')
    exercise = models.ForeignKey(Exercise, on_delete=models.CASCADE)
    reps = models.IntegerField()
    difficulty = models.CharField(max_length=50, blank=True, null=True)
    target_range = models.CharField(max_length=100, blank=True, null=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='PENDING')
    assigned_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.exercise.name} for {self.patient.username}"

class SessionResult(models.Model):
    patient = models.ForeignKey(User, on_delete=models.CASCADE)
    exercise = models.ForeignKey(Exercise, on_delete=models.CASCADE)
    accuracy = models.FloatField() # Percentage
    time_taken = models.IntegerField() # Seconds
    score = models.IntegerField()
    date = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Result: {self.exercise.name} - {self.patient.username} - {self.accuracy}%"
