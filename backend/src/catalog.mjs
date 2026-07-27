export const catalog = [
  {
    id: "aurora",
    title: "Aurora Timelapse",
    summary: "Night sky field capture",
    kind: "video",
    tags: ["night", "motion"],
    durationSeconds: 15,
    byteSize: 2498125,
    checksum: "demo-aurora-v1",
    palette: ["#67E8F9", "#8B5CF6", "#07101F"]
  },
  {
    id: "coast",
    title: "Coastal Drift",
    summary: "Low tide from the cliff path",
    kind: "video",
    tags: ["ocean", "calm"],
    durationSeconds: 12,
    byteSize: 1876432,
    checksum: "demo-coast-v1",
    palette: ["#5EEAD4", "#0284C7", "#082F49"]
  },
  {
    id: "city",
    title: "After Rain",
    summary: "Reflections across a late train platform",
    kind: "video",
    tags: ["city", "night"],
    durationSeconds: 10,
    byteSize: 2210448,
    checksum: "demo-city-v1",
    palette: ["#F472B6", "#6366F1", "#111827"]
  },
  {
    id: "forest",
    title: "Forest Detail",
    summary: "A quiet macro study of moss and fern",
    kind: "image",
    tags: ["nature", "macro"],
    durationSeconds: null,
    byteSize: 184420,
    checksum: "demo-forest-v1",
    palette: ["#A3E635", "#15803D", "#052E16"]
  }
];

export function publicItem(item, origin) {
  return {
    id: item.id,
    title: item.title,
    summary: item.summary,
    kind: item.kind,
    tags: item.tags,
    durationSeconds: item.durationSeconds,
    imageURL: `${origin}/v1/media/${item.id}/poster.svg`,
    videoURL: item.kind === "video"
      ? `${origin}/v1/media/${item.id}/video.mp4`
      : null,
    updatedAt: "2026-07-27T06:00:00.000Z",
    byteSize: item.byteSize,
    checksum: item.checksum
  };
}
