// DOM Elements
const navLinks = document.querySelectorAll('.nav-link');
const counters = document.querySelectorAll('.counter-number');
const contactForm = document.getElementById('contactForm');
const hamburger = document.querySelector('.hamburger');
const navMenu = document.querySelector('.nav-menu');

// Sayfa yükleme
document.addEventListener('DOMContentLoaded', () => {
    initializeCalendar();
    startCounters();
    setupNavigation();
    setupMobileMenu();
    setupForm();
});

// Navigasyon Menüsü İşlevselliği
function setupNavigation() {
    navLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            navLinks.forEach(l => l.classList.remove('active'));
            link.classList.add('active');
            closeMenu();
        });
    });

    // Scroll sırasında aktif menüyü güncelle
    window.addEventListener('scroll', () => {
        let currentSection = '';
        const sections = document.querySelectorAll('section');

        sections.forEach(section => {
            const sectionTop = section.offsetTop - 100;
            if (window.scrollY >= sectionTop) {
                currentSection = section.getAttribute('id');
            }
        });

        navLinks.forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href').slice(1) === currentSection) {
                link.classList.add('active');
            }
        });
    });
}

// Mobil Menü
function setupMobileMenu() {
    hamburger.addEventListener('click', () => {
        navMenu.style.display = navMenu.style.display === 'flex' ? 'none' : 'flex';
    });
}

function closeMenu() {
    if (window.innerWidth <= 768) {
        navMenu.style.display = 'none';
    }
}

// Sayaç Animasyonu
function startCounters() {
    const observerOptions = {
        threshold: 0.5
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting && !entry.target.classList.contains('animated')) {
                animateCounters();
                entry.target.classList.add('animated');
            }
        });
    }, observerOptions);

    const counterSection = document.querySelector('.counter-section');
    observer.observe(counterSection);
}

function animateCounters() {
    counters.forEach(counter => {
        const target = parseInt(counter.getAttribute('data-target'));
        let count = 0;
        const increment = Math.ceil(target / 50);
        const speed = 30;

        const updateCount = () => {
            count += increment;
            if (count < target) {
                counter.textContent = count;
                setTimeout(updateCount, speed);
            } else {
                counter.textContent = target;
            }
        };

        updateCount();
    });
}

// Takvim İşlevselliği
const events = {
    2026: {
        5: [5, 12, 19, 26], // Haziran
        6: [7, 14, 21, 28]  // Temmuz
    }
};

let currentDate = new Date();

function initializeCalendar() {
    displayCalendar();
    setupCalendarNavigation();
}

function setupCalendarNavigation() {
    const prevBtn = document.getElementById('prevMonth');
    const nextBtn = document.getElementById('nextMonth');

    prevBtn.addEventListener('click', () => {
        currentDate.setMonth(currentDate.getMonth() - 1);
        displayCalendar();
    });

    nextBtn.addEventListener('click', () => {
        currentDate.setMonth(currentDate.getMonth() + 1);
        displayCalendar();
    });
}

function displayCalendar() {
    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();
    const monthName = new Intl.DateTimeFormat('tr-TR', { month: 'long', year: 'numeric' }).format(currentDate);
    
    document.getElementById('currentMonth').textContent = monthName.charAt(0).toUpperCase() + monthName.slice(1);

    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    const prevLastDay = new Date(year, month, 0);

    const firstDayIndex = firstDay.getDay() === 0 ? 6 : firstDay.getDay() - 1; // Pazartesi başla
    const lastDateOfMonth = lastDay.getDate();
    const prevLastDate = prevLastDay.getDate();
    const nextDays = 7 - lastDay.getDay() === 0 ? 0 : 7 - lastDay.getDay();

    const calendarDays = document.getElementById('calendarDays');
    calendarDays.innerHTML = '';

    // Önceki ayın günleri
    for (let i = firstDayIndex; i > 0; i--) {
        const dayElement = createDayElement(prevLastDate - i + 1, 'empty');
        calendarDays.appendChild(dayElement);
    }

    // Mevcut ayın günleri
    for (let date = 1; date <= lastDateOfMonth; date++) {
        const isToday = date === new Date().getDate() && 
                       month === new Date().getMonth() && 
                       year === new Date().getFullYear();
        
        const hasEvent = events[year] && events[year][month] && events[year][month].includes(date);
        const dayElement = createDayElement(date, isToday ? 'today' : hasEvent ? 'event' : 'normal', date);
        calendarDays.appendChild(dayElement);
    }

    // Sonraki ayın günleri
    for (let date = 1; date <= nextDays; date++) {
        const dayElement = createDayElement(date, 'empty');
        calendarDays.appendChild(dayElement);
    }
}

function createDayElement(date, type, fullDate = null) {
    const dayElement = document.createElement('div');
    dayElement.classList.add('calendar-day', type);
    dayElement.textContent = date;

    if (type === 'event' && fullDate) {
        dayElement.title = `Eğitim Günü: ${fullDate}. ${currentDate.toLocaleString('tr-TR', { month: 'long' })}`;
        dayElement.style.cursor = 'pointer';
        dayElement.addEventListener('click', () => {
            alert(`Eğitim Programı: ${fullDate}. ${currentDate.toLocaleString('tr-TR', { month: 'long' })}\n\nLütfen daha fazla bilgi için iletişime geçiniz.`);
        });
    }

    return dayElement;
}

// Form İşlevselliği
function setupForm() {
    contactForm.addEventListener('submit', (e) => {
        e.preventDefault();

        // Form verilerini al
        const formData = new FormData(contactForm);
        const inputs = contactForm.querySelectorAll('input, textarea, select');

        // Basit doğrulama
        let isValid = true;
        inputs.forEach(input => {
            if (!input.value.trim()) {
                input.style.borderColor = '#e74c3c';
                isValid = false;
            } else {
                input.style.borderColor = '#27ae60';
            }
        });

        if (isValid) {
            // Başarılı mesajı göster
            showFormMessage('Mesajınız başarıyla gönderildi! En kısa zamanda sizinle iletişime geçeceğiz.', 'success');
            
            // Formu temizle
            contactForm.reset();
            inputs.forEach(input => {
                input.style.borderColor = '';
            });

            // Mesajı 4 saniye sonra kaldır
            setTimeout(() => {
                removeFormMessage();
            }, 4000);
        } else {
            showFormMessage('Lütfen tüm alanları doldurduğunuzdan emin olunuz.', 'error');
        }
    });

    // Input focusunda hata rengini kaldır
    contactForm.querySelectorAll('input, textarea, select').forEach(input => {
        input.addEventListener('focus', () => {
            input.style.borderColor = '';
        });
    });
}

function showFormMessage(message, type) {
    const messageDiv = document.createElement('div');
    messageDiv.className = `form-message ${type}`;
    messageDiv.textContent = message;
    messageDiv.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: ${type === 'success' ? '#2ecc71' : '#e74c3c'};
        color: white;
        padding: 15px 20px;
        border-radius: 8px;
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.2);
        z-index: 10000;
        font-weight: 600;
        animation: slideInRight 0.3s ease-out;
    `;

    document.body.appendChild(messageDiv);

    // CSS animasyonu için stil ekle
    const style = document.createElement('style');
    style.textContent = `
        @keyframes slideInRight {
            from {
                opacity: 0;
                transform: translateX(400px);
            }
            to {
                opacity: 1;
                transform: translateX(0);
            }
        }
    `;
    if (!document.querySelector('style[data-form-message]')) {
        style.setAttribute('data-form-message', 'true');
        document.head.appendChild(style);
    }
}

function removeFormMessage() {
    const messageDiv = document.querySelector('.form-message');
    if (messageDiv) {
        messageDiv.style.animation = 'slideOutRight 0.3s ease-out';
        setTimeout(() => messageDiv.remove(), 300);
    }
}

// Smooth scroll animasyonu
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        const href = this.getAttribute('href');
        if (href !== '#') {
            e.preventDefault();
            const target = document.querySelector(href);
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        }
    });
});

// Keşfet butonu işlevselliği
document.querySelector('.btn-primary').addEventListener('click', () => {
    document.getElementById('about').scrollIntoView({ behavior: 'smooth' });
});

// Responsive menü güncellemesi
window.addEventListener('resize', () => {
    if (window.innerWidth > 768) {
        navMenu.style.display = 'flex';
    } else {
        navMenu.style.display = 'none';
    }
});

// Sayfa yüklendiğinde menü durumunu ayarla
window.addEventListener('load', () => {
    if (window.innerWidth <= 768) {
        navMenu.style.display = 'none';
    }
});

// Scroll animasyonları
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -100px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.animation = 'slideInUp 0.6s ease-out';
            observer.unobserve(entry.target);
        }
    });
}, observerOptions);

// Animasyonları uygula
document.querySelectorAll('.course-card, .gallery-item, .info-item').forEach(element => {
    observer.observe(element);
});
