document.addEventListener('DOMContentLoaded', () => {
    // --- Hero Slider Logic ---
    const slides = document.querySelectorAll('.slide');
    const nextBtn = document.querySelector('.next-btn');
    const prevBtn = document.querySelector('.prev-btn');
    let currentSlide = 0;
    let slideInterval;

    const showSlide = (n) => {
        // Remove current classes
        slides[currentSlide].classList.remove('active');
        slides[currentSlide].classList.add('last-active');

        // Wait for removal of last-active from other slides
        slides.forEach((slide, index) => {
            if (index !== currentSlide) {
                slide.classList.remove('last-active');
            }
        });

        // Set new current slide
        currentSlide = (n + slides.length) % slides.length;
        slides[currentSlide].classList.add('active');

        // Reset interval to prevent double jumping
        resetInterval();
    };

    const nextSlide = () => showSlide(currentSlide + 1);
    const prevSlide = () => showSlide(currentSlide - 1);

    const resetInterval = () => {
        if (slideInterval) clearInterval(slideInterval);
        slideInterval = setInterval(nextSlide, 5000); // 5 seconds
    };

    if (nextBtn && prevBtn) {
        nextBtn.addEventListener('click', nextSlide);
        prevBtn.addEventListener('click', prevSlide);
    }

    // Initialize auto-play
    resetInterval();

    // --- Statistics Counter Animation ---
    const stats = document.querySelectorAll('.stat-number');
    const observerOptions = {
        threshold: 0.5
    };

    const statsObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const target = parseInt(entry.target.getAttribute('data-target'));
                const count = () => {
                    const current = parseInt(entry.target.innerText);
                    const increment = Math.ceil(target / 50);
                    if (current < target) {
                        entry.target.innerText = Math.min(current + increment, target);
                        setTimeout(count, 30);
                    }
                };
                count();
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);

    stats.forEach(stat => statsObserver.observe(stat));

    // --- Sticky Navbar Effect ---
    window.addEventListener('scroll', () => {
        const navbar = document.getElementById('navbar');
        if (window.scrollY > 50) {
            navbar.style.padding = '10px 0';
            navbar.style.boxShadow = 'var(--shadow-sm)';
        } else {
            navbar.style.padding = '20px 0';
            navbar.style.boxShadow = 'none';
        }
    });

    // --- Mobile Menu Toggle ---
    const mobileMenu = document.getElementById('mobile-menu');
    const navLinks = document.getElementById('nav-links');

    if (mobileMenu) {
        mobileMenu.addEventListener('click', () => {
            navLinks.classList.toggle('active');
            mobileMenu.classList.toggle('open');
        });
    }

    // Close mobile menu on link click
    document.querySelectorAll('.nav-links a').forEach(link => {
        link.addEventListener('click', () => {
            navLinks.classList.remove('active');
            mobileMenu.classList.remove('open');
        });
    });
});
