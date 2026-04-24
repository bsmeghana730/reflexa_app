from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from rest_framework import viewsets, status
from rest_framework.response import Response
from rest_framework.decorators import action
from .models import Exercise, ExerciseAssignment, SessionResult, Profile, TherapistRequest
from .serializers import ExerciseSerializer, ExerciseAssignmentSerializer, SessionResultSerializer
from django.contrib.auth.models import User
from django.http import JsonResponse

# API ViewSets
class ExerciseViewSet(viewsets.ModelViewSet):
    queryset = Exercise.objects.all()
    serializer_class = ExerciseSerializer

class AssignmentViewSet(viewsets.ModelViewSet):
    queryset = ExerciseAssignment.objects.all()
    serializer_class = ExerciseAssignmentSerializer

    @action(detail=False, methods=['get'])
    def patient_assignments(self, request):
        patient_id = request.query_params.get('patient_id')
        if not patient_id:
            return Response({"error": "patient_id is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        assignments = ExerciseAssignment.objects.filter(patient_id=patient_id)
        serializer = self.get_serializer(assignments, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def request_exercise(self, request):
        patient_id = request.data.get('patient_id')
        exercise_id = request.data.get('exercise_id')
        
        if not patient_id or not exercise_id:
            return Response({"error": "patient_id and exercise_id are required"}, status=status.HTTP_400_BAD_REQUEST)
        
        exercise = Exercise.objects.get(id=exercise_id)
        assignment = ExerciseAssignment.objects.create(
            patient_id=patient_id,
            exercise=exercise,
            reps=exercise.default_reps,
            status='PENDING'
        )
        return Response(self.get_serializer(assignment).data, status=status.HTTP_201_CREATED)

class SessionResultViewSet(viewsets.ModelViewSet):
    queryset = SessionResult.objects.all()
    serializer_class = SessionResultSerializer

# Template Views
from django.contrib.auth import login, authenticate, logout
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from .forms import ExtendedUserCreationForm

def signup_view(request):
    if request.method == 'POST':
        form = ExtendedUserCreationForm(request.POST)
        if form.is_valid():
            user = form.save()
            role = form.cleaned_data.get('role')
            profile, _ = Profile.objects.get_or_create(user=user)
            profile.role = role
            profile.save()
            login(request, user)
            if role == 'THERAPIST':
                return redirect('therapist_dashboard')
            return redirect('patient_request')
    else:
        form = ExtendedUserCreationForm()
    return render(request, 'rehab/signup.html', {'form': form})

def login_view(request):
    if request.method == 'POST':
        form = AuthenticationForm(data=request.POST)
        if form.is_valid():
            user = form.get_user()
            login(request, user)
            if hasattr(user, 'profile') and user.profile.role == 'THERAPIST':
                return redirect('therapist_dashboard')
            return redirect('patient_request')
    else:
        form = AuthenticationForm()
    return render(request, 'rehab/login.html', {'form': form})

def logout_view(request):
    logout(request)
    return redirect('login')

def therapist_dashboard(request):
    if not request.user.is_authenticated:
        return redirect('login')
    
    # Allow superusers OR therapists
    is_therapist = hasattr(request.user, 'profile') and request.user.profile.role == 'THERAPIST'
    if not (request.user.is_superuser or is_therapist):
        return redirect('login')
    
    try:
        therapist = request.user
        patients = User.objects.filter(profile__therapist=therapist)
        requests = TherapistRequest.objects.filter(therapist=therapist, status='PENDING')
        
        patient_data = []
        for patient in patients:
            results = SessionResult.objects.filter(patient=patient).order_by('-date')
            avg_accuracy = sum([r.accuracy for r in results]) / len(results) if results else 0
            latest_result = results.first() if results else None
            
            try:
                profile = patient.profile
            except Profile.DoesNotExist:
                profile = Profile.objects.create(user=patient, role='PATIENT')
                
            patient_data.append({
                'user': patient,
                'profile': profile,
                'avg_accuracy': round(avg_accuracy, 1),
                'latest_result': latest_result,
                'session_count': results.count()
            })

        context = {
            'therapist': therapist,
            'patients': patient_data,
            'requests': requests
        }
        return render(request, 'rehab/therapist_dashboard.html', context)
    except Exception as e:
        print(f"Error in therapist_dashboard: {e}")
        return render(request, 'rehab/error.html', {'message': str(e)})

def patient_request(request):
    if request.method == 'POST':
        therapist_id = request.POST.get('therapist_id')
        therapist = get_object_or_404(User, id=therapist_id)
        
        # If user is logged in, use their data, otherwise create a placeholder patient
        if request.user.is_authenticated:
            patient = request.user
        else:
            # Create a temporary guest user account if email doesn't exist
            email = request.POST.get('email')
            username = email.split('@')[0]
            patient, created = User.objects.get_or_create(email=email, defaults={'username': username})
            if created:
                patient.set_unusable_password()
                patient.save()
                Profile.objects.create(user=patient, role='PATIENT')

        TherapistRequest.objects.create(
            patient=patient,
            therapist=therapist,
            name=request.POST.get('name'),
            age=request.POST.get('age'),
            phone=request.POST.get('phone'),
            email=request.POST.get('email'),
            injury_type=request.POST.get('injury_type'),
            status='PENDING'
        )
        return redirect('request_success')

    therapists = User.objects.filter(profile__role='THERAPIST')
    return render(request, 'rehab/patient_request.html', {'therapists': therapists})

def request_success(request):
    return render(request, 'rehab/request_success.html')

def approve_request(request, request_id):
    ther_request = get_object_or_404(TherapistRequest, id=request_id)
    ther_request.status = 'APPROVED'
    ther_request.save()
    
    # Update patient's profile with therapist
    patient_profile, _ = Profile.objects.get_or_create(user=ther_request.patient)
    patient_profile.role = 'PATIENT'
    patient_profile.therapist = ther_request.therapist
    # Update other details if needed
    patient_profile.age = ther_request.age
    patient_profile.phone = ther_request.phone
    patient_profile.medical_condition = ther_request.injury_type
    patient_profile.save()
    
    return redirect('therapist_dashboard')

def reject_request(request, request_id):
    ther_request = get_object_or_404(TherapistRequest, id=request_id)
    ther_request.status = 'REJECTED'
    ther_request.save()
    return redirect('therapist_dashboard')

