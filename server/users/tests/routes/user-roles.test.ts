import { BOBATAN_USER_ID, JERSEY_DEVIL_USER_ID } from "test/data/auth";
import {
  TWISTED_MINDS_REALM_EXTERNAL_ID,
  UWU_REALM_EXTERNAL_ID,
} from "test/data/realms";
import { setLoggedInUser, startTestServer } from "utils/test-utils";

import request from "supertest";
import router from "../../routes";

jest.mock("server/cache");
jest.mock("handlers/auth");

describe("Tests users/@me/bobadex endpoint", () => {
  const server = startTestServer(router);

  test("prevents unauthorized access to the @me user roles endpoint", async () => {
    const res = await request(server.app).get(
      `/@me/realms/${TWISTED_MINDS_REALM_EXTERNAL_ID}/roles`
    );
    expect(res.status).toBe(401);
  });

  xtest("returns the logged in user's roles (user with no roles)", async () => {
    setLoggedInUser(JERSEY_DEVIL_USER_ID);
    const res = await request(server.app).get(
      `/@me/realms/${TWISTED_MINDS_REALM_EXTERNAL_ID}/roles`
    );
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ roles: [] });
  });

  xtest("returns the logged in user's roles (user with a role)", async () => {
    setLoggedInUser(BOBATAN_USER_ID);
    const res = await request(server.app).get(
      `/@me/realms/${UWU_REALM_EXTERNAL_ID}/roles`
    );
    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      roles: [
        {
          id: "70485a1e-4ce9-4064-bd87-440e16b2f219",
          name: "The Memester",
          avatar:
            "https://firebasestorage.googleapis.com/v0/b/bobaboard-fb.appspot.com/o/images%2Fbobaland%2Fc26e8ce9-a547-4ff4-9486-7a2faca4d873%2F01af97fa-e240-4002-81fb-7abec9ee984b?alt=media&token=ac14effe-a788-47ae-b3b8-cbb3d8ad8f94",
          color: "blue",
          description: "A role for the real memers.",
          permissions: ["all"],
          boards: ["0e0d1ee6-f996-4415-89c1-c9dc1fe991dc"],
          accessory: null,
        },
      ],
    });
  });
});
