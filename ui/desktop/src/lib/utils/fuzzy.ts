/**
 * Fuzzy search utilities for command bar
 * Provides intelligent matching across tabs, history, bookmarks, and page content
 */

export interface FuzzyMatch {
	item: unknown;
	score: number;
	matches: MatchRange[];
	matchedField: string;
}

export interface MatchRange {
	start: number;
	end: number;
	text: string;
}

export interface SearchableItem {
	id: string;
	title: string;
	url: string;
	content?: string;
	snippet?: string;
	keywords?: string[];
	timestamp?: number;
}

/**
 * Fuzzy match score calculation
 * Higher score = better match
 */
export function fuzzyScore(query: string, target: string): { score: number; matches: MatchRange[] } {
	if (!query || !target) return { score: 0, matches: [] };
	
	const queryLower = query.toLowerCase();
	const targetLower = target.toLowerCase();
	
	// Exact match gets highest score
	if (targetLower === queryLower) {
		return { score: 1000, matches: [{ start: 0, end: target.length, text: target }] };
	}
	
	// Starts with query gets high score
	if (targetLower.startsWith(queryLower)) {
		return { 
			score: 900 + (query.length / target.length) * 100, 
			matches: [{ start: 0, end: query.length, text: target.slice(0, query.length) }] 
		};
	}
	
	// Contains query as substring
	const substringIndex = targetLower.indexOf(queryLower);
	if (substringIndex !== -1) {
		return {
			score: 700 + (query.length / target.length) * 100 - substringIndex * 2,
			matches: [{ start: substringIndex, end: substringIndex + query.length, text: target.slice(substringIndex, substringIndex + query.length) }]
		};
	}
	
	// Word boundary matching
	const words = targetLower.split(/[\s\-_./]+/);
	const queryWords = queryLower.split(/\s+/);
	let wordScore = 0;
	const wordMatches: MatchRange[] = [];
	
	for (const qWord of queryWords) {
		for (let i = 0; i < words.length; i++) {
			if (words[i].startsWith(qWord)) {
				wordScore += 50 + (qWord.length / words[i].length) * 30;
				const wordStart = targetLower.indexOf(words[i]);
				wordMatches.push({ start: wordStart, end: wordStart + qWord.length, text: target.slice(wordStart, wordStart + qWord.length) });
				break;
			}
		}
	}
	
	if (wordScore > 0) {
		return { score: wordScore, matches: wordMatches };
	}
	
	// Character-by-character fuzzy matching
	let score = 0;
	let targetIndex = 0;
	let consecutiveMatches = 0;
	const charMatches: MatchRange[] = [];
	let currentMatchStart = -1;
	
	for (let i = 0; i < queryLower.length; i++) {
		const char = queryLower[i];
		let found = false;
		
		for (let j = targetIndex; j < targetLower.length; j++) {
			if (targetLower[j] === char) {
				if (currentMatchStart === -1) {
					currentMatchStart = j;
				}
				
				score += 10;
				
				// Bonus for consecutive matches
				if (j === targetIndex) {
					consecutiveMatches++;
					score += consecutiveMatches * 5;
				} else {
					// Close match with gap
					if (currentMatchStart !== -1) {
						charMatches.push({ 
							start: currentMatchStart, 
							end: j, 
							text: target.slice(currentMatchStart, j) 
						});
					}
					currentMatchStart = j;
					consecutiveMatches = 1;
					score -= (j - targetIndex) * 2; // Penalty for gaps
				}
				
				// Bonus for matching at word boundaries
				if (j === 0 || /[\s\-_./]/.test(target[j - 1])) {
					score += 15;
				}
				
				targetIndex = j + 1;
				found = true;
				break;
			}
		}
		
		if (!found) {
			// Character not found, significant penalty
			score -= 20;
			if (currentMatchStart !== -1) {
				charMatches.push({ 
					start: currentMatchStart, 
					end: targetIndex, 
					text: target.slice(currentMatchStart, targetIndex) 
				});
				currentMatchStart = -1;
			}
		}
	}
	
	// Close final match range
	if (currentMatchStart !== -1) {
		charMatches.push({ 
			start: currentMatchStart, 
			end: targetIndex, 
			text: target.slice(currentMatchStart, targetIndex) 
		});
	}
	
	// Bonus for matching a larger percentage of the query
	const matchRatio = charMatches.reduce((acc, m) => acc + (m.end - m.start), 0) / query.length;
	score += matchRatio * 20;
	
	return { score: Math.max(0, score), matches: charMatches };
}

/**
 * Highlight matched portions of text
 */
export function highlightMatches(text: string, matches: MatchRange[]): string {
	if (!matches.length) return text;
	
	// Sort matches by start position
	const sortedMatches = [...matches].sort((a, b) => a.start - b.start);
	
	let result = '';
	let lastEnd = 0;
	
	for (const match of sortedMatches) {
		if (match.start >= lastEnd) {
			result += text.slice(lastEnd, match.start);
			result += `<mark>${text.slice(match.start, match.end)}</mark>`;
			lastEnd = match.end;
		}
	}
	
	result += text.slice(lastEnd);
	return result;
}

/**
 * Search through a collection of items
 */
export function fuzzySearch<T extends SearchableItem>(
	query: string,
	items: T[],
	options: {
		fields?: (keyof T)[];
		minScore?: number;
		maxResults?: number;
		boostRecent?: boolean;
	} = {}
): FuzzyMatch[] {
	const { 
		fields = ['title', 'url', 'content', 'keywords'] as (keyof T)[], 
		minScore = 10,
		maxResults = 50,
		boostRecent = true
	} = options;
	
	const results: FuzzyMatch[] = [];
	const now = Date.now();
	
	for (const item of items) {
		let bestScore = 0;
		let bestMatches: MatchRange[] = [];
		let bestField = '';
		
		for (const field of fields) {
			const value = item[field];
			if (!value) continue;
			
			if (Array.isArray(value)) {
				// Handle keyword arrays
				for (const keyword of value) {
					const { score, matches } = fuzzyScore(query, String(keyword));
					if (score > bestScore) {
						bestScore = score;
						bestMatches = matches;
						bestField = String(field);
					}
				}
			} else {
				const { score, matches } = fuzzyScore(query, String(value));
				
				// Weight title matches higher
				const fieldWeight = field === 'title' ? 1.5 : field === 'url' ? 1.2 : 1;
				const weightedScore = score * fieldWeight;
				
				if (weightedScore > bestScore) {
					bestScore = weightedScore;
					bestMatches = matches;
					bestField = String(field);
				}
			}
		}
		
		// Apply recency boost
		if (boostRecent && item.timestamp) {
			const ageInHours = (now - item.timestamp) / (1000 * 60 * 60);
			if (ageInHours < 1) bestScore *= 1.5;
			else if (ageInHours < 24) bestScore *= 1.3;
			else if (ageInHours < 168) bestScore *= 1.1; // Within a week
		}
		
		if (bestScore >= minScore) {
			results.push({
				item,
				score: bestScore,
				matches: bestMatches,
				matchedField: bestField
			});
		}
	}
	
	// Sort by score descending
	results.sort((a, b) => b.score - a.score);
	
	return results.slice(0, maxResults);
}

/**
 * Extract searchable content snippets from HTML
 */
export function extractTextContent(html: string, maxLength: number = 5000): string {
	// Remove script and style tags
	let text = html.replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '');
	text = text.replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '');
	
	// Remove HTML tags
	text = text.replace(/<[^>]+>/g, ' ');
	
	// Decode HTML entities
	text = text.replace(/&nbsp;/g, ' ')
		.replace(/&amp;/g, '&')
		.replace(/&lt;/g, '<')
		.replace(/&gt;/g, '>')
		.replace(/&quot;/g, '"')
		.replace(/&#39;/g, "'");
	
	// Normalize whitespace
	text = text.replace(/\s+/g, ' ').trim();
	
	return text.slice(0, maxLength);
}

/**
 * Find content snippets that match a query
 */
export function findContentSnippets(
	content: string, 
	query: string, 
	contextSize: number = 50
): string[] {
	const snippets: string[] = [];
	const queryLower = query.toLowerCase();
	const contentLower = content.toLowerCase();
	
	let searchIndex = 0;
	while (snippets.length < 3) {
		const matchIndex = contentLower.indexOf(queryLower, searchIndex);
		if (matchIndex === -1) break;
		
		const start = Math.max(0, matchIndex - contextSize);
		const end = Math.min(content.length, matchIndex + query.length + contextSize);
		
		let snippet = content.slice(start, end);
		if (start > 0) snippet = '...' + snippet;
		if (end < content.length) snippet = snippet + '...';
		
		snippets.push(snippet);
		searchIndex = matchIndex + query.length;
	}
	
	return snippets;
}

/**
 * Parse URL for searchable parts
 */
export function parseUrlParts(url: string): string[] {
	try {
		const parsed = new URL(url);
		const parts: string[] = [];
		
		// Domain parts
		parts.push(...parsed.hostname.split('.').filter(p => p.length > 2));
		
		// Path parts
		const pathParts = parsed.pathname.split('/').filter(Boolean);
		parts.push(...pathParts.map(p => p.replace(/[-_]/g, ' ')));
		
		// Query params (just values that look like content)
		for (const [, value] of parsed.searchParams) {
			if (value.length > 3 && value.length < 50 && !/^[0-9]+$/.test(value)) {
				parts.push(value);
			}
		}
		
		return parts;
	} catch {
		return [url];
	}
}

/**
 * Check if query matches a search engine trigger keyword
 */
export function detectSearchEngine(
	query: string,
	engines: { keyword: string; name: string }[]
): { engine: { keyword: string; name: string }; remainingQuery: string } | null {
	const queryLower = query.toLowerCase().trim();
	
	// Check for exact keyword match followed by space
	for (const engine of engines) {
		const keyword = engine.keyword.toLowerCase();
		if (queryLower.startsWith(keyword + ' ')) {
			return {
				engine,
				remainingQuery: query.slice(keyword.length + 1).trim()
			};
		}
		// Also check if query exactly matches or starts with keyword
		if (queryLower === keyword || queryLower.startsWith(keyword)) {
			return {
				engine,
				remainingQuery: query.slice(keyword.length).trim()
			};
		}
	}
	
	return null;
}

/**
 * Generate Google "I'm Feeling Lucky" URL
 */
export function getLuckySearchUrl(query: string): string {
	return `https://www.google.com/search?q=${encodeURIComponent(query)}&btnI=I%27m+Feeling+Lucky`;
}

/**
 * Tokenize text for content indexing
 */
export function tokenize(text: string): string[] {
	return text
		.toLowerCase()
		.replace(/[^\w\s]/g, ' ')
		.split(/\s+/)
		.filter(word => word.length > 2);
}

/**
 * Build a simple inverted index for content search
 */
export class ContentIndex {
	private index: Map<string, Set<string>> = new Map();
	private documents: Map<string, { title: string; url: string; content: string }> = new Map();
	
	addDocument(id: string, title: string, url: string, content: string) {
		this.documents.set(id, { title, url, content });
		
		const tokens = new Set([
			...tokenize(title),
			...tokenize(url),
			...tokenize(content)
		]);
		
		for (const token of tokens) {
			if (!this.index.has(token)) {
				this.index.set(token, new Set());
			}
			this.index.get(token)!.add(id);
		}
	}
	
	removeDocument(id: string) {
		this.documents.delete(id);
		
		// Remove from inverted index
		for (const [, docIds] of this.index) {
			docIds.delete(id);
		}
	}
	
	search(query: string): Array<{ id: string; title: string; url: string; snippet: string }> {
		const queryTokens = tokenize(query);
		if (!queryTokens.length) return [];
		
		// Find documents that contain all query tokens
		const matchingDocs = new Map<string, number>();
		
		for (const token of queryTokens) {
			// Also check partial matches
			for (const [indexToken, docIds] of this.index) {
				if (indexToken.startsWith(token) || indexToken.includes(token)) {
					for (const docId of docIds) {
						matchingDocs.set(docId, (matchingDocs.get(docId) || 0) + 1);
					}
				}
			}
		}
		
		// Sort by match count
		const sorted = [...matchingDocs.entries()]
			.sort((a, b) => b[1] - a[1])
			.slice(0, 20);
		
		return sorted.map(([id]) => {
			const doc = this.documents.get(id)!;
			const snippets = findContentSnippets(doc.content, query);
			return {
				id,
				title: doc.title,
				url: doc.url,
				snippet: snippets[0] || doc.content.slice(0, 100) + '...'
			};
		});
	}
	
	clear() {
		this.index.clear();
		this.documents.clear();
	}
}
