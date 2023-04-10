import { BOBATAN_USER_ID, JERSEY_DEVIL_USER_ID } from "test/data/auth";
import {
  CROWN_ACCESSORY_EXTERNAL_ID,
  GOREMASTER_ROLE_EXTERNAL_ID,
  MEMESTER_ROLE_EXTERNAL_ID,
  OWNER_ROLE_EXTERNAL_ID,
} from "test/data/user";
import {
  TWISTED_MINDS_REALM_EXTERNAL_ID,
  UWU_REALM_EXTERNAL_ID,
} from "test/data/realms";
import { setLoggedInUser, startTestServer } from "utils/test-utils";

import { GORE_BOARD_ID } from "test/data/boards";
import request from "supertest";
import router from "../../routes";

jest.mock("server/cache");
jest.mock("handlers/auth");

describe("Tests users/@me/realms/:realmId/roles endpoint", () => {
  const server = startTestServer(router);

  test("prevents unauthorized access to the @me user roles endpoint", async () => {
    const res = await request(server.app).get(
      `/@me/realms/${TWISTED_MINDS_REALM_EXTERNAL_ID}/roles`
    );
    expect(res.status).toBe(401);
  });

  test("returns the logged in user's roles on the given realm (user with no roles)", async () => {
    setLoggedInUser(JERSEY_DEVIL_USER_ID);
    const res = await request(server.app).get(
      `/@me/realms/${TWISTED_MINDS_REALM_EXTERNAL_ID}/roles`
    );
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ roles: [] });
  });

  test("returns the logged in user's roles (user with one role)", async () => {
    setLoggedInUser(BOBATAN_USER_ID);
    const res = await request(server.app).get(
      `/@me/realms/${UWU_REALM_EXTERNAL_ID}/roles`
    );
    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      roles: [
        {
          id: MEMESTER_ROLE_EXTERNAL_ID,
          name: "The Memester",
          avatar:
            "https://firebasestorage.googleapis.com/v0/b/bobaboard-fb.appspot.com/o/images%2Fbobaland%2Fc26e8ce9-a547-4ff4-9486-7a2faca4d873%2F01af97fa-e240-4002-81fb-7abec9ee984b?alt=media&token=ac14effe-a788-47ae-b3b8-cbb3d8ad8f94",
          color: "blue",
          description: "A role for the real memers.",
          permissions: {
            // TODO: this role has "all" permissions - I don't know if it's actually ALL all; figure this out and update
            boardPermissions: ["edit_board_details"],
            postPermissions: [
              "edit_content",
              "edit_whisper_tags",
              "edit_category_tags",
              "edit_index_tags",
              "edit_content_notices",
              // TODO: see if post_as_role should also be here
            ],
            threadPermissions: ["move_thread"],
            realmPermissions: [
              "create_realm_invite",
              "post_on_realm",
              "comment_on_realm",
              "create_thread_on_realm",
              "access_locked_boards_on_realm",
            ],
          },
          boards: ["0e0d1ee6-f996-4415-89c1-c9dc1fe991dc"],
          accessory: null,
        },
      ],
    });
  });

  test("returns the logged in user's roles (user with multiple roles", async () => {
    setLoggedInUser(BOBATAN_USER_ID);
    const res = await request(server.app).get(
      `/@me/realms/${TWISTED_MINDS_REALM_EXTERNAL_ID}/roles`
    );
    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      roles: [
        {
          id: GOREMASTER_ROLE_EXTERNAL_ID,
          name: "GoreMaster5000",
          avatar:
            "https://firebasestorage.googleapis.com/v0/b/bobaboard-fb.appspot.com/o/images%2Fbobaland%2Fc26e8ce9-a547-4ff4-9486-7a2faca4d873%2F6518df53-2031-4ac5-8d75-57a0051ed924?alt=media&token=23df54b7-297c-42ff-a0ea-b9862c9814f8",
          color: "red",
          description: "A role for people who can edit the gore board.",
          permissions: {
            boardPermissions: ["edit_board_details"],
            postPermissions: [
              "edit_content",
              "edit_category_tags",
              "edit_content_notices",
              // TODO: clarify category for post as role
              "post_as_role",
            ],
            realmPermissions: [],
          },
          boards: [GORE_BOARD_ID],
          accessory: null,
        },
        {
          id: OWNER_ROLE_EXTERNAL_ID,
          name: "The Owner",
          avatar:
            "https://firebasestorage.googleapis.com/v0/b/bobaboard-fb.appspot.com/o/images%2Fbobaland%2Fundefined%2F2df7dfb4-4c64-4370-8e74-9ee30948f05d?alt=media&token=26b16bef-0fd2-47b5-b6df-6cf2799010ca",
          color: "pink",
          description: "A role for the owner.",
          permissions: {
            boardPermissions: ["edit_board_details"],
            // TODO: clarify category for post as role
            postPermissions: ["post_as_role"],
            threadPermissions: ["move_thread"],
            realmPermissions: ["create_realm_invite"],
          },
          boards: [],
          accessory: CROWN_ACCESSORY_EXTERNAL_ID
        },
      ],
    });
  });
});
