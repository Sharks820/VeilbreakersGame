// Battle Chasers Reference Image Downloader v2
// Downloads via browser context to handle CDN authentication

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const OUTPUT_DIR = './battle_chasers_refs';
const TARGET_COUNT = 30;
const DELAY_MS = 2500;

let imageCounter = 0;
const downloadedUrls = new Set();

if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function downloadViaPage(page, imageUrl, filepath) {
    try {
        // Use the browser's fetch to download (includes cookies/auth)
        const response = await page.evaluate(async (url) => {
            try {
                const res = await fetch(url, {
                    credentials: 'include',
                    headers: { 'Accept': 'image/*' }
                });
                if (!res.ok) return { error: `HTTP ${res.status}` };
                const blob = await res.blob();
                const arrayBuffer = await blob.arrayBuffer();
                return { data: Array.from(new Uint8Array(arrayBuffer)), type: blob.type };
            } catch (e) {
                return { error: e.message };
            }
        }, imageUrl);

        if (response.error) {
            throw new Error(response.error);
        }

        fs.writeFileSync(filepath, Buffer.from(response.data));
        return true;
    } catch (e) {
        throw e;
    }
}

async function collectArtStationImages(page, baseUrl) {
    console.log(`\nVisiting: ${baseUrl}`);
    const images = [];

    try {
        await page.goto(baseUrl, { waitUntil: 'domcontentloaded', timeout: 45000 });
        await delay(3000);

        // Scroll to load more content
        for (let i = 0; i < 4; i++) {
            await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
            await delay(2000);
        }

        // Click on project thumbnails to get to actual project pages
        const projectLinks = await page.evaluate(() => {
            const links = new Set();
            document.querySelectorAll('a').forEach(a => {
                if (a.href && a.href.includes('/artwork/')) {
                    links.add(a.href);
                }
            });
            return Array.from(links).slice(0, 12);
        });

        console.log(`  Found ${projectLinks.length} project links`);

        for (const projectUrl of projectLinks) {
            if (images.length >= 15) break;

            try {
                await page.goto(projectUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });
                await delay(2000);

                // Get high-res image URLs
                const projectImages = await page.evaluate(() => {
                    const imgs = [];
                    // Get all images and convert to largest size
                    document.querySelectorAll('img').forEach(img => {
                        let src = img.src || '';
                        if (src.includes('artstation.com') && src.includes('/assets/')) {
                            // Try to get the largest version
                            // Pattern: .../large/xxx.jpg or .../4k/xxx.jpg
                            src = src.replace(/\/smaller_square\/|\/small\/|\/medium\//, '/large/');
                            if (!src.includes('/covers/') && !src.includes('avatar')) {
                                imgs.push(src);
                            }
                        }
                    });

                    // Also look for asset viewer images
                    document.querySelectorAll('img[data-src]').forEach(img => {
                        let src = img.dataset.src || '';
                        if (src.includes('artstation.com')) {
                            src = src.replace(/\/smaller_square\/|\/small\/|\/medium\//, '/large/');
                            imgs.push(src);
                        }
                    });

                    return [...new Set(imgs)];
                });

                for (const imgUrl of projectImages) {
                    if (!downloadedUrls.has(imgUrl) && imgUrl.length > 40) {
                        images.push(imgUrl);
                        downloadedUrls.add(imgUrl);
                    }
                }

                console.log(`    Project images: ${projectImages.length}, total: ${images.length}`);
            } catch (e) {
                console.log(`    Error: ${e.message}`);
            }
        }
    } catch (e) {
        console.log(`  Error: ${e.message}`);
    }

    return images;
}

async function collectWikiImages(page) {
    console.log('\nVisiting: Battle Chasers Wiki');
    const images = [];

    const wikiPages = [
        'https://battlechasersnightwar.fandom.com/wiki/Gully',
        'https://battlechasersnightwar.fandom.com/wiki/Garrison',
        'https://battlechasersnightwar.fandom.com/wiki/Red_Monika',
        'https://battlechasersnightwar.fandom.com/wiki/Calibretto',
        'https://battlechasersnightwar.fandom.com/wiki/Knolan',
        'https://battlechasersnightwar.fandom.com/wiki/Alumon',
        'https://battlechasersnightwar.fandom.com/wiki/Battle_Chasers:_Nightwar'
    ];

    for (const wikiUrl of wikiPages) {
        try {
            await page.goto(wikiUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });
            await delay(1500);

            const pageImages = await page.evaluate(() => {
                const imgs = [];
                document.querySelectorAll('img.pi-image-thumbnail, .image img, figure img').forEach(img => {
                    let src = img.src || img.dataset.src || '';
                    // Get full resolution
                    src = src.split('/revision/')[0];
                    if (src.includes('static.wikia') && !src.includes('thumbnail') && src.length > 50) {
                        imgs.push(src);
                    }
                });
                return imgs;
            });

            for (const imgUrl of pageImages) {
                if (!downloadedUrls.has(imgUrl)) {
                    images.push(imgUrl);
                    downloadedUrls.add(imgUrl);
                }
            }

            console.log(`  ${wikiUrl.split('/').pop()}: ${pageImages.length} images`);
        } catch (e) {
            console.log(`  Error on ${wikiUrl}: ${e.message}`);
        }
    }

    return images;
}

async function collectGoogleImages(page) {
    console.log('\nSearching Google Images for high-quality refs...');
    const images = [];

    const searches = [
        'Battle Chasers Nightwar character art official',
        'Joe Madureira Battle Chasers artwork',
        'Gully Battle Chasers Nightwar',
        'Calibretto war golem Battle Chasers',
        'Red Monika Battle Chasers art'
    ];

    for (const query of searches) {
        if (images.length >= 15) break;

        try {
            const searchUrl = `https://www.google.com/search?q=${encodeURIComponent(query)}&tbm=isch&tbs=isz:l`;
            await page.goto(searchUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });
            await delay(2000);

            // Scroll to load more
            await page.evaluate(() => window.scrollTo(0, 800));
            await delay(1000);

            const searchImages = await page.evaluate(() => {
                const imgs = [];
                document.querySelectorAll('img').forEach(img => {
                    const src = img.src || '';
                    // Get data URLs or high-res image URLs
                    if (src.startsWith('data:image') && src.length > 1000) {
                        // Skip data URLs, we want actual image links
                    } else if (src.includes('gstatic.com/images') && src.length > 100) {
                        imgs.push(src);
                    }
                });
                return imgs.slice(0, 5);
            });

            images.push(...searchImages);
            console.log(`  "${query}": ${searchImages.length} images`);
        } catch (e) {
            console.log(`  Search error: ${e.message}`);
        }
    }

    return images;
}

async function main() {
    console.log('='.repeat(60));
    console.log('Battle Chasers Reference Image Downloader v2');
    console.log('='.repeat(60));

    const browser = await chromium.launch({
        headless: true
    });

    const context = await browser.newContext({
        userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        viewport: { width: 1920, height: 1080 },
        javaScriptEnabled: true,
        acceptDownloads: true
    });

    const page = await context.newPage();

    let allImages = [];

    // Collect from various sources
    const joeImages = await collectArtStationImages(page, 'https://joemadx.artstation.com/projects');
    allImages.push(...joeImages);

    const graceImages = await collectArtStationImages(page, 'https://graceliu.artstation.com/albums/644503');
    allImages.push(...graceImages);

    const billyImages = await collectArtStationImages(page, 'https://billygarretsen.artstation.com/projects');
    allImages.push(...billyImages);

    const wikiImages = await collectWikiImages(page);
    allImages.push(...wikiImages);

    // Remove duplicates
    allImages = [...new Set(allImages)];
    console.log(`\nTotal unique images found: ${allImages.length}`);

    // Download phase
    console.log('\n' + '='.repeat(60));
    console.log('Downloading images...');
    console.log('='.repeat(60));

    const downloaded = [];
    const failed = [];

    for (const imageUrl of allImages) {
        if (imageCounter >= TARGET_COUNT) break;

        const ext = imageUrl.match(/\.(jpg|jpeg|png|webp|gif)/i)?.[1] || 'jpg';
        const filename = `bc_${String(imageCounter + 1).padStart(3, '0')}.${ext}`;
        const filepath = path.join(OUTPUT_DIR, filename);

        console.log(`[${imageCounter + 1}/${TARGET_COUNT}] ${filename}`);

        try {
            await downloadViaPage(page, imageUrl, filepath);

            const stats = fs.statSync(filepath);
            if (stats.size < 10000) {
                fs.unlinkSync(filepath);
                console.log(`  Skipped (too small)`);
                continue;
            }

            downloaded.push({ filename, size: stats.size });
            imageCounter++;
            console.log(`  OK (${(stats.size / 1024).toFixed(1)} KB)`);
            await delay(DELAY_MS);
        } catch (e) {
            failed.push({ url: imageUrl.substring(0, 50), error: e.message });
            console.log(`  Failed: ${e.message}`);
        }
    }

    await browser.close();

    // Summary
    console.log('\n' + '='.repeat(60));
    console.log('DOWNLOAD SUMMARY');
    console.log('='.repeat(60));
    console.log(`Downloaded: ${downloaded.length} images`);
    console.log(`Failed: ${failed.length}`);
    console.log(`Directory: ${path.resolve(OUTPUT_DIR)}`);
    console.log('');

    let totalSize = 0;
    for (const file of downloaded) {
        console.log(`  ${file.filename} (${(file.size / 1024).toFixed(1)} KB)`);
        totalSize += file.size;
    }
    console.log(`\nTotal size: ${(totalSize / 1024 / 1024).toFixed(2)} MB`);
    console.log('='.repeat(60));
}

main().catch(console.error);
