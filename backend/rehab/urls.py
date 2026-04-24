from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    ExerciseViewSet, AssignmentViewSet, SessionResultViewSet,
    therapist_dashboard, patient_request, request_success,
    approve_request, reject_request, signup_view, login_view, logout_view
)

router = DefaultRouter()
router.register(r'exercises', ExerciseViewSet)
router.register(r'assignments', AssignmentViewSet)
router.register(r'results', SessionResultViewSet)

urlpatterns = [
    # API endpoints
    path('api/', include(router.urls)),
    
    # Auth views
    path('signup/', signup_view, name='signup'),
    path('login/', login_view, name='login'),
    path('logout/', logout_view, name='logout'),
    
    # Template views
    path('', therapist_dashboard, name='home'),
    path('dashboard/', therapist_dashboard, name='therapist_dashboard'),
    path('request/', patient_request, name='patient_request'),
    path('request/success/', request_success, name='request_success'),
    path('request/approve/<int:request_id>/', approve_request, name='approve_request'),
    path('request/reject/<int:request_id>/', reject_request, name='reject_request'),
]
