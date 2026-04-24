const meditationData = [
    { id: 1, title: "Deep Breathing", duration: "10 min", icon: "fa-wind", color: "#CAFFEB", audio: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3" },
    { id: 2, title: "Stress Relief", duration: "15 min", icon: "fa-brain", color: "#D5E8FF", audio: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3" },
    { id: 3, title: "Mindfulness", duration: "12 min", icon: "fa-spa", color: "#E3D5FF", audio: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3" },
    { id: 4, title: "Body Relaxation", duration: "20 min", icon: "fa-child", color: "#98FFD9", audio: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3" },
    { id: 5, title: "Sleep Meditation", duration: "30 min", icon: "fa-moon", color: "#D5E8FF", audio: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3" },
    { id: 6, title: "Focus Booster", duration: "8 min", icon: "fa-bolt", color: "#E3D5FF", audio: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3" }
];

// DOM Elements
const homeScreen = document.getElementById('home-screen');
const sessionScreen = document.getElementById('session-screen');
const meditationGrid = document.querySelector('.meditation-grid');
const breathingCircle = document.getElementById('breathing-circle');
const secondsCount = document.getElementById('seconds-count');
const sessionStatus = document.getElementById('session-status');
const instructionText = document.getElementById('instruction-text');
const playPauseBtn = document.querySelector('.play-pause-btn');
const backToHome = document.querySelector('.back-to-home');
const bgAudio = document.getElementById('bg-audio');

let breathingInterval;
let timerSeconds = 4;
let isExhaling = false;
let isPaused = false;

// Initialize App
function init() {
    populateGrid();
    setupEventListeners();
}

// Populate Home Grid
function populateGrid() {
    meditationGrid.innerHTML = meditationData.map(item => `
        <div class="meditation-card" onclick="startSession(${item.id})">
            <div class="card-icon-wrap" style="background-color: ${item.color}">
                <i class="fa-solid ${item.icon}"></i>
            </div>
            <h3>${item.title}</h3>
            <p>${item.duration}</p>
            <div class="card-play"><i class="fa-solid fa-circle-play"></i></div>
        </div>
    `).join('');
}

// Navigation
function startSession(id) {
    const session = meditationData.find(s => s.id === id);
    homeScreen.classList.remove('active');
    sessionScreen.classList.add('active');
    
    // Set audio and data
    document.querySelector('#session-screen .session-title').innerText = session.title;
    bgAudio.src = session.audio;
    bgAudio.play().catch(e => console.log("Audio play blocked by browser. User interaction required."));
    
    startBreathing();
}

function closeSession() {
    stopBreathing();
    bgAudio.pause();
    bgAudio.currentTime = 0;
    sessionScreen.classList.remove('active');
    homeScreen.classList.add('active');
}

// Breathing Logic
function startBreathing() {
    isPaused = false;
    isExhaling = false;
    timerSeconds = 4;
    updatePhaseUI();
    
    breathingInterval = setInterval(() => {
        if (isPaused) return;

        timerSeconds--;
        
        if (timerSeconds < 0) {
            isExhaling = !isExhaling;
            timerSeconds = 4;
            updatePhaseUI();
        }
        
        secondsCount.innerText = timerSeconds.toString().padStart(2, '0');
    }, 1000);
}

function stopBreathing() {
    clearInterval(breathingInterval);
}

function updatePhaseUI() {
    if (isExhaling) {
        breathingCircle.classList.remove('inhale');
        breathingCircle.classList.add('exhale');
        sessionStatus.innerText = "Breathe Out...";
        instructionText.innerText = "Let go of all tension. Release your breath slowly and completely.";
    } else {
        breathingCircle.classList.remove('exhale');
        breathingCircle.classList.add('inhale');
        sessionStatus.innerText = "Breathe In...";
        instructionText.innerText = "Let the air fill your chest. Focus on the gentle expansion of the circle.";
    }
}

// Event Listeners
function setupEventListeners() {
    backToHome.onclick = closeSession;
    
    playPauseBtn.onclick = () => {
        isPaused = !isPaused;
        const icon = playPauseBtn.querySelector('i');
        if (isPaused) {
            icon.className = 'fa-solid fa-play';
            bgAudio.pause();
        } else {
            icon.className = 'fa-solid fa-pause';
            bgAudio.play();
        }
    };
    
    document.querySelector('.reset-btn').onclick = () => {
        stopBreathing();
        startBreathing();
    };
}

init();
