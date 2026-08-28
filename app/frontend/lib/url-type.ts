import type { BadgeTone } from "@/components/ui/badge";

export type UrlType = "website" | "youtube" | "tiktok" | "linkedin" | "facebook";

// Label + badge tone for each bookmark link type. Tones map to the
// platform badge colors in design-system.css:
//   youtube -> red, website -> grey, tiktok -> black, social -> blue.
export const URL_TYPE_META: Record<UrlType, { label: string; tone: BadgeTone }> = {
  youtube: { label: "YouTube", tone: "youtube" },
  website: { label: "Website", tone: "website" },
  tiktok: { label: "TikTok", tone: "tiktok" },
  linkedin: { label: "LinkedIn", tone: "social" },
  facebook: { label: "Facebook", tone: "social" },
};

export function urlTypeMeta(urlType: string): { label: string; tone: BadgeTone } {
  return URL_TYPE_META[urlType as UrlType] ?? URL_TYPE_META.website;
}
