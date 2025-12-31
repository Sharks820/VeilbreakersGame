// Battle Chasers Reference Image Downloader
// Uses Playwright to scrape high-quality reference images for LoRA training

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

const OUTPUT_DIR = './battle_chasers_refs';
const TARGET_COUNT = 30;
const DELAY_MS = 2500; // 2.5 seconds between downloads

// Track downloaded images to skip duplicates
const downloadedUrls = new Set();
const downloadedHashes = new Set();
let imageCounter = 0;

// Create output directory
if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
    console.log(`Created directory: ${OUTPUT_DIR}`);
}

// Helper: delay
function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// Helper: download image
function downloadImage(url, filepath) {
    return new Promise((resolve, reject) => {
        const protocol = url.startsWith('https') ? https : http;

        const request = protocol.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Referer': 'https://www.artstation.com/',
                'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8'
            }
        }, (response) => {
            // Handle redirects
            if (response.statusCode === 301 || response.statusCode === 302) {
                downloadImage(response.headers.location, filepath)
                    .then(resolve)
                    .catch(reject);
                return;
            }

            if (response.statusCode !== 200) {
                reject(new Error(`HTTP ${response.statusCode}`));
                return;
            }

            const fileStream = fs.createWriteStream(filepath);
            response.pipe(fileStream);

            fileStream.on('finish', () => {
                fileStream.close();
                resolve(true);
            });

            fileStream.on('error', (err) => {
                fs.unlink(filepath, () => {});
                reject(err);
            });
        });

        request.on('error', reject);
        request.setTimeout(30000, () => {
            request.destroy();
            reject(new Error('Timeout'));
        });
    });
}

// Get file extension from URL or content type
function getExtension(url) {
    const match = url.match(/\.(jpg|jpeg|png|webp|gif)/i);
    return match ? match[1].toLowerCase() : 'jpg';
}

// Scrape ArtStation project page for images
async function scrapeArtStationProjects(page, url, artistName) {
    console.log(`\n--- Scraping ${artistName} ArtStation ---`);
    const images = [];

    try {
        await page.goto(url, { waitUntil: 'networkidle', timeout: 60000 });
        await delay(2000);

        // Scroll to load more projects
        for (let i = 0; i < 3; i++) {
            await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
            await delay(1500);
        }

        // Get project links
        const projectLinks = await page.evaluate(() => {
            const links = [];
            document.querySelectorAll('a[href*="/artwork/"]').forEach(a => {
                if (a.href && !links.includes(a.href)) {
                    links.push(a.href);
                }
            });
            return links.slice(0, 15); // Limit to 15 projects per artist
        });

        console.log(`Found ${projectLinks.length} projects`);

        // Visit each project and get high-res images
        for (const projectUrl of projectLinks) {
            if (imageCounter >= TARGET_COUNT) break;

            try {
                await page.goto(projectUrl, { waitUntil: 'networkidle', timeout: 30000 });
                await delay(1500);

                // Get all image URLs from the project
                const projectImages = await page.evaluate(() => {
                    const imgs = [];
                    // Look for high-res image URLs in various places
                    document.querySelectorAll('img').forEach(img => {
                        let src = img.src || img.dataset.src || '';
                        // Convert to larger size if possible
                        if (src.includes('artstation')) {
                            src = src.replace(/\/smaller_square\/|\/small\/|\/medium\/|\/large\//, '/4k/');
                            src = src.replace(/\/\d+x\d+\//, '/original/');
                        }
                        if (src && (src.includes('cdna.artstation') || src.includes('cdnb.artstation'))) {
                            imgs.push(src);
                        }
                    });
                    return imgs;
                });

                for (const imgUrl of projectImages) {
                    if (!downloadedUrls.has(imgUrl) && imgUrl.length > 20) {
                        images.push(imgUrl);
                        downloadedUrls.add(imgUrl);
                    }
                }
            } catch (e) {
                console.log(`  Error on project: ${e.message}`);
            }
        }
    } catch (e) {
        console.log(`Error scraping ${artistName}: ${e.message}`);
    }

    return images;
}

// Scrape ArtStation album
async function scrapeArtStationAlbum(page, url, albumName) {
    console.log(`\n--- Scraping ${albumName} Album ---`);
    const images = [];

    try {
        await page.goto(url, { waitUntil: 'networkidle', timeout: 60000 });
        await delay(2000);

        // Scroll to load all images
        for (let i = 0; i < 5; i++) {
            await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
            await delay(1500);
        }

        // Get all images from album
        const albumImages = await page.evaluate(() => {
            const imgs = [];
            document.querySelectorAll('img').forEach(img => {
                let src = img.src || img.dataset.src || '';
                if (src.includes('artstation')) {
                    src = src.replace(/\/smaller_square\/|\/small\/|\/medium\/|\/large\//, '/4k/');
                }
                if (src && (src.includes('cdna.artstation') || src.includes('cdnb.artstation'))) {
                    imgs.push(src);
                }
            });
            return imgs;
        });

        for (const imgUrl of albumImages) {
            if (!downloadedUrls.has(imgUrl) && imgUrl.length > 20) {
                images.push(imgUrl);
                downloadedUrls.add(imgUrl);
            }
        }

        console.log(`Found ${images.length} images in album`);
    } catch (e) {
        console.log(`Error scraping album: ${e.message}`);
    }

    return images;
}

// Scrape Fandom wiki
async function scrapeFandomWiki(page, url) {
    console.log(`\n--- Scraping Battle Chasers Wiki ---`);
    const images = [];

    try {
        await page.goto(url, { waitUntil: 'networkidle', timeout: 60000 });
        await delay(2000);

        // Get category page images
        const categoryImages = await page.evaluate(() => {
            const imgs = [];
            document.querySelectorAll('.category-page__member-thumbnail img, .gallery img, a.image img').forEach(img => {
                let src = img.src || img.dataset.src || '';
                // Get full resolution from Fandom
                src = src.replace(/\/revision\/latest\/scale-to-width-down\/\d+/, '/revision/latest');
                src = src.replace(/\/revision\/latest\/thumbnail\/[^/]+/, '/revision/latest');
                if (src && src.includes('static.wikia')) {
                    imgs.push(src);
                }
            });
            return imgs;
        });

        // Also get links to individual image pages
        const imagePageLinks = await page.evaluate(() => {
            const links = [];
            document.querySelectorAll('a.category-page__member-link').forEach(a => {
                if (a.href && a.href.includes('File:')) {
                    links.push(a.href);
                }
            });
            return links.slice(0, 20);
        });

        console.log(`Found ${imagePageLinks.length} image page links`);

        // Visit each image page for full resolution
        for (const imagePageUrl of imagePageLinks) {
            if (imageCounter >= TARGET_COUNT) break;

            try {
                await page.goto(imagePageUrl, { waitUntil: 'networkidle', timeout: 30000 });
                await delay(1000);

                const fullResImages = await page.evaluate(() => {
                    const imgs = [];
                    // Look for the full resolution image link
                    const fullResLink = document.querySelector('a.internal[href*="static.wikia"]');
                    if (fullResLink) {
                        imgs.push(fullResLink.href);
                    }
                    // Also check main image
                    const mainImg = document.querySelector('.fullImageLink img, .fullMedia img');
                    if (mainImg && mainImg.src) {
                        imgs.push(mainImg.src.replace(/\/revision\/latest\/scale-to-width-down\/\d+/, '/revision/latest'));
                    }
                    return imgs;
                });

                for (const imgUrl of fullResImages) {
                    if (!downloadedUrls.has(imgUrl)) {
                        images.push(imgUrl);
                        downloadedUrls.add(imgUrl);
                    }
                }
            } catch (e) {
                // Skip errors on individual pages
            }
        }

        // Add category page images too
        for (const imgUrl of categoryImages) {
            if (!downloadedUrls.has(imgUrl)) {
                images.push(imgUrl);
                downloadedUrls.add(imgUrl);
            }
        }

        console.log(`Total wiki images found: ${images.length}`);
    } catch (e) {
        console.log(`Error scraping wiki: ${e.message}`);
    }

    return images;
}

// Main function
async function main() {
    console.log('='.repeat(60));
    console.log('Battle Chasers Reference Image Downloader');
    console.log('='.repeat(60));
    console.log(`Target: ${TARGET_COUNT} images`);
    console.log(`Output: ${OUTPUT_DIR}`);
    console.log('='.repeat(60));

    const browser = await chromium.launch({
        headless: true,
        args: ['--disable-blink-features=AutomationControlled']
    });

    const context = await browser.newContext({
        userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        viewport: { width: 1920, height: 1080 }
    });

    const page = await context.newPage();

    // Collect all image URLs
    let allImages = [];

    // 1. Joe Madureira ArtStation (Priority - original artist)
    const joeImages = await scrapeArtStationProjects(page, 'https://joemadx.artstation.com/projects', 'Joe Madureira');
    allImages = allImages.concat(joeImages);

    // 2. Grace Liu ArtStation Album
    const graceImages = await scrapeArtStationAlbum(page, 'https://graceliu.artstation.com/albums/644503', 'Grace Liu BC');
    allImages = allImages.concat(graceImages);

    // 3. Billy Garretsen ArtStation
    const billyImages = await scrapeArtStationProjects(page, 'https://billygarretsen.artstation.com/projects', 'Billy Garretsen');
    allImages = allImages.concat(billyImages);

    // 4. Battle Chasers Wiki
    const wikiImages = await scrapeFandomWiki(page, 'https://battlechasersnightwar.fandom.com/wiki/Category:Hero_images');
    allImages = allImages.concat(wikiImages);

    await browser.close();

    // Remove duplicates and filter
    const uniqueImages = [...new Set(allImages)].filter(url => {
        return url &&
               url.length > 30 &&
               !url.includes('avatar') &&
               !url.includes('icon') &&
               !url.includes('logo') &&
               (url.includes('.jpg') || url.includes('.jpeg') || url.includes('.png') || url.includes('.webp') || url.includes('artstation') || url.includes('wikia'));
    });

    console.log(`\n${'='.repeat(60)}`);
    console.log(`Total unique images found: ${uniqueImages.length}`);
    console.log(`Downloading up to ${TARGET_COUNT} images...`);
    console.log('='.repeat(60));

    // Download images
    const downloaded = [];
    const failed = [];

    for (const imageUrl of uniqueImages) {
        if (imageCounter >= TARGET_COUNT) break;

        try {
            const ext = getExtension(imageUrl);
            const filename = `bc_${String(imageCounter + 1).padStart(3, '0')}.${ext}`;
            const filepath = path.join(OUTPUT_DIR, filename);

            console.log(`[${imageCounter + 1}/${TARGET_COUNT}] Downloading: ${filename}`);

            await downloadImage(imageUrl, filepath);

            // Verify file was created and has content
            const stats = fs.statSync(filepath);
            if (stats.size < 5000) {
                fs.unlinkSync(filepath);
                console.log(`  Skipped (too small: ${stats.size} bytes)`);
                continue;
            }

            downloaded.push({
                filename,
                size: stats.size,
                url: imageUrl.substring(0, 80) + '...'
            });

            imageCounter++;
            console.log(`  Success (${(stats.size / 1024).toFixed(1)} KB)`);

            await delay(DELAY_MS);
        } catch (e) {
            failed.push({ url: imageUrl.substring(0, 60), error: e.message });
            console.log(`  Failed: ${e.message}`);
        }
    }

    // Print summary
    console.log('\n' + '='.repeat(60));
    console.log('DOWNLOAD SUMMARY');
    console.log('='.repeat(60));
    console.log(`Successfully downloaded: ${downloaded.length} images`);
    console.log(`Failed: ${failed.length}`);
    console.log(`Output directory: ${path.resolve(OUTPUT_DIR)}`);
    console.log('');

    console.log('Downloaded files:');
    console.log('-'.repeat(40));
    let totalSize = 0;
    for (const file of downloaded) {
        console.log(`  ${file.filename} (${(file.size / 1024).toFixed(1)} KB)`);
        totalSize += file.size;
    }
    console.log('-'.repeat(40));
    console.log(`Total size: ${(totalSize / 1024 / 1024).toFixed(2)} MB`);

    if (failed.length > 0) {
        console.log('\nFailed downloads:');
        for (const f of failed.slice(0, 5)) {
            console.log(`  ${f.url}... - ${f.error}`);
        }
        if (failed.length > 5) {
            console.log(`  ... and ${failed.length - 5} more`);
        }
    }

    console.log('\n' + '='.repeat(60));
    console.log('Done! Images ready for LoRA training.');
    console.log('='.repeat(60));
}

main().catch(console.error);
