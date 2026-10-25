# Halloween startup animation layers

Created on 24 October 2026 with the built-in image editor. These are animation
layers only; launcher icons and their native catalogs are unchanged.

Reference: `assets/clashking/icons/android/drawable-nodpi/app_icon_halloween_mark.png`.

## Crown

Saved as `crown.png`, from generated `exec-bfdb69ad-0ad7-48d0-92a7-25430f11484d.png`.
Canvas: 1254 × 1254, transparent. Alpha bounds above 32/255: left 46, top 266,
right 1207, bottom 986. The view maps these bounds to the original icon's crown
position, without cropping or modifying the saved raster.

Prompt:

> Create an animation layer from the supplied existing logo. Extract ONLY the orange crown with its original white cobweb, golden beveled edges and orange facets. REMOVE EVERY PART OF THE ARROW: the black feather shape above, the arrowhead/black shaft below, AND the ivory diagonal slash / impact marks across the crown. Reconstruct the removed ivory slash with continuous orange facets matching its exact surrounding crown. Preserve the crown's exact silhouette, original shape, proportions and colors; no redesign. Transparent background, no backplate or shadow. Only the clean crown should remain, centered. This is the crown BEFORE arrow impact.

The same crown stays mounted after impact. An ivory vector strike mark is
revealed over it, avoiding a shape change between separately generated crowns.

## Arrow ends

Saved as `arrow-ends.png`, from generated
`exec-f71a2bb4-5971-4432-a03d-0fa939b80c46.png`.
Canvas: 1254 × 1254, transparent. Alpha bounds above 32/255: left 280, top 29,
right 1118, bottom 1212. The pieces share one image plane so the original
animation can move them as a single arrow. The crown occludes the inner shafts.

Prompt:

> Create an animation layer from the supplied existing logo. Extract ONLY the two black arrow-end pieces: the upper-right feather/fletching and the lower-left black shaft plus arrowhead. Preserve their exact shapes, ivory outlines, and their EXACT RELATIVE POSITIONS, orientations, distances, and proportions from the reference. Remove the ENTIRE orange crown and cobweb, and REMOVE the central ivory diagonal slash that was drawn across the orange crown. Do not join the two separate pieces: the space formerly occupied by the crown must remain transparent. This is two disconnected pieces of a single arrow; keep both on one transparent square canvas. No orange pixels, no crown, no backplate, no shadows, no added objects.

## Motion contract

`StartupBrand` remains the only animation timeline: 770 ms, unchanged flight,
recoil, impact sparks and wordmark reveal. Both native image layers must fire
`onLoad` before that timeline starts. Reduced motion still shows the final state
immediately. Do not reintroduce SVG masks on bitmap layers: the supplied iOS
recording showed the masked crown missing until the unmasked impact layer appeared.
