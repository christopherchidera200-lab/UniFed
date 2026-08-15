import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { MapPin, Accessibility, Search, Locate, Building2 } from "lucide-react";
import { unifedApi, getToken, type CampusPlaceDTO } from "@/lib/api";
import { SectionHeader, Card, IconBadge } from "@/components/ui/Card";

const KINDS = [
  "all", "lecture_hall", "lab", "library", "hostel", "cafeteria",
  "sports", "parking", "shuttle_stop", "admin", "other"
];

const KIND_LABEL: Record<string, string> = {
  all: "All", lecture_hall: "Lecture Halls", lab: "Labs", library: "Library",
  hostel: "Hostels", cafeteria: "Cafeteria", sports: "Sports", parking: "Parking",
  shuttle_stop: "Shuttle", admin: "Admin", other: "Other"
};

/** Smart Campus — browse places by category and proximity (Phase 3). */
export default function CampusPage() {
  const token = getToken();
  const [kind, setKind] = useState("all");
  const [nearby, setNearby] = useState<{ lat: number; lng: number } | null>(null);

  const places = useQuery<Array<CampusPlaceDTO & { distance_km?: number }>>({
    queryKey: ["campus-places", kind, nearby],
    queryFn: () =>
      nearby
        ? unifedApi.campusNear(nearby.lat, nearby.lng, kind !== "all" ? { kind } : {})
        : unifedApi.campusPlaces(kind !== "all" ? { kind } : {}),
    enabled: true
  });

  function locate() {
    if (typeof navigator === "undefined" || !navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(
      (pos) => setNearby({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
      () => setNearby(null)
    );
  }

  return (
    <div className="space-y-6">
      <SectionHeader title="Smart Campus" eyebrow="Find your way around" />

      {/* Category chips */}
      <div className="flex gap-2 overflow-x-auto pb-1">
        {KINDS.map((k) => (
          <button
            key={k}
            onClick={() => setKind(k)}
            className={
              "shrink-0 text-xs px-3 py-1.5 rounded-pill font-medium transition-colors " +
              (kind === k
                ? "bg-navy-600 text-white"
                : "bg-navy-100 text-navy-600 dark:bg-navy-800 dark:text-navy-200")
            }
          >
            {KIND_LABEL[k]}
          </button>
        ))}
      </div>

      <div className="flex items-center justify-between">
        <p className="text-ink-muted text-xs">
          {nearby ? "Sorted by distance from you" : "Showing campus places"}
        </p>
        <button
          onClick={locate}
          className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-pill border border-navy-200 dark:border-navy-700 text-navy-600 dark:text-navy-200 hover:bg-navy-50 dark:hover:bg-navy-800 transition-colors"
        >
          <Locate size={14} /> Near me
        </button>
      </div>

      {places.isLoading && <Card className="text-ink-muted text-sm">Locating places…</Card>}
      {places.isError && (
        <Card className="text-amber-700 dark:text-amber-300 text-sm">
          Could not load campus places.
        </Card>
      )}

      <Card className="divide-y divide-navy-50 dark:divide-navy-800/60 p-0">
        {places.data?.map((p) => (
          <div key={p.id} className="flex items-start gap-3 px-4 py-3">
            <IconBadge className="bg-saffron-100 text-saffron-600 dark:bg-saffron-500/20 dark:text-saffron-300">
              <MapPin size={18} />
            </IconBadge>
            <div className="flex-1 min-w-0">
              <div className="font-medium text-ink">{p.name}</div>
              <div className="text-ink-subtle text-xs capitalize">
                {KIND_LABEL[p.kind] ?? p.kind}
              </div>
              {p.description && (
                <div className="text-ink-muted text-xs mt-1">{p.description}</div>
              )}
              <div className="flex flex-wrap gap-2 mt-1.5">
                {p.accessibility_level && (
                  <span className="flex items-center gap-1 text-[11px] px-2 py-0.5 rounded-pill bg-emerald-100 text-emerald-700 dark:bg-emerald-500/20 dark:text-emerald-300">
                    <Accessibility size={12} /> {p.accessibility_level}
                  </span>
                )}
                {typeof p.distance_km === "number" && (
                  <span className="text-[11px] px-2 py-0.5 rounded-pill bg-brand-100 text-brand-700 dark:bg-brand-500/20 dark:text-brand-300">
                    {p.distance_km.toFixed(1)} km
                  </span>
                )}
              </div>
            </div>
          </div>
        ))}
        {places.data?.length === 0 && (
          <p className="px-4 py-3 text-ink-muted text-sm">No places in this category yet.</p>
        )}
      </Card>

      <p className="text-ink-muted text-xs text-center flex items-center justify-center gap-1.5">
        <Building2 size={13} /> Smart-Campus data is node-scoped to your university.
      </p>
    </div>
  );
}
